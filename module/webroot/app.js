(() => {
  if (window.apatch !== undefined && window.apatch.ksu === undefined) window.ksu = window.apatch;

  const MODULE = "sh /data/adb/modules/ksu_app_freezer/manage.sh";
  const EXEC_OPTIONS = JSON.stringify({ env: { PATH: "/system/bin:/data/adb/ksu/bin" } });
  const knownNames = {
    android: "Sistema Android",
    "com.android.systemui": "Interfaccia di sistema",
    "com.android.settings": "Impostazioni",
    "com.android.phone": "Telefono Android",
    "com.android.vending": "Google Play Store",
    "com.google.android.gms": "Google Play Services",
    "com.google.android.gsf": "Google Services Framework",
    "com.google.android.inputmethod.latin": "Gboard",
    "dev.patrickgold.florisboard": "FlorisBoard"
  };

  let apps = [];
  let filter = "all";
  let query = "";
  let callbackCounter = 0;
  let pendingResolve = null;
  let toastTimer;

  const $ = id => document.getElementById(id);

  function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'";
  }

  function execKsu(command) {
    return new Promise((resolve, reject) => {
      if (!window.ksu || typeof window.ksu.exec !== "function") {
        reject(new Error("Apri questa schermata dall'app KernelSU."));
        return;
      }

      const callback = `freezer_exec_${Date.now()}_${++callbackCounter}`;
      window[callback] = (errno, stdout, stderr) => {
        delete window[callback];
        const result = {
          errno: Number(errno),
          stdout: stdout || "",
          stderr: stderr || ""
        };
        if (result.errno === 0) resolve(result);
        else reject(Object.assign(new Error(result.stderr || result.stdout || `Errore ${result.errno}`), result));
      };

      try {
        window.ksu.exec(command, EXEC_OPTIONS, callback);
      } catch (error) {
        delete window[callback];
        reject(error);
      }
    });
  }

  function titleCase(value) {
    return value.replace(/[_-]+/g, " ").replace(/\b\w/g, letter => letter.toUpperCase());
  }

  function parseList(output) {
    const lines = output.replace(/\r/g, "").split("\n");
    if (lines.shift() !== "FREEZER_LIST_V2") throw new Error("Risposta del modulo non riconosciuta.");

    return lines.filter(Boolean).map(line => {
      const [pkg, rawName, kind, state, critical, reason, managed] = line.split("\t");
      const fallback = titleCase(pkg.split(".").pop() || pkg);
      return {
        pkg,
        name: knownNames[pkg] || titleCase(rawName || fallback),
        kind,
        state,
        critical: critical === "yes",
        reason: reason || "",
        managed: managed === "yes"
      };
    });
  }

  function makeBadge(text, className) {
    const element = document.createElement("span");
    element.className = `badge ${className}`;
    element.textContent = text;
    return element;
  }

  function render() {
    $("totalCount").textContent = apps.length;
    $("activeCount").textContent = apps.filter(app => app.state === "active").length;
    $("frozenCount").textContent = apps.filter(app => app.state === "frozen").length;

    const normalized = query.trim().toLocaleLowerCase("it");
    const visible = apps.filter(app => {
      const matchesText = !normalized || `${app.name} ${app.pkg}`.toLocaleLowerCase("it").includes(normalized);
      const matchesFilter = filter === "all"
        || app.state === filter
        || app.kind === filter
        || (filter === "critical" && app.critical);
      return matchesText && matchesFilter;
    });

    const list = $("list");
    list.replaceChildren();

    if (!visible.length) {
      const empty = document.createElement("div");
      empty.className = "empty";
      empty.textContent = "Nessuna app corrisponde ai filtri selezionati.";
      list.appendChild(empty);
      return;
    }

    visible.forEach(app => {
      const card = document.createElement("article");
      card.className = `app${app.critical ? " critical" : ""}`;

      const avatar = document.createElement("div");
      avatar.className = "avatar";
      avatar.textContent = (app.name[0] || "?").toLocaleUpperCase("it");

      const body = document.createElement("div");
      const name = document.createElement("div");
      name.className = "app-name";
      name.textContent = app.name;
      const pkg = document.createElement("div");
      pkg.className = "package";
      pkg.textContent = app.pkg;
      const badges = document.createElement("div");
      badges.className = "badges";
      badges.appendChild(makeBadge(app.state === "active" ? "Attiva" : "Congelata", app.state));
      badges.appendChild(makeBadge(app.kind === "system" ? "Sistema" : "Utente", app.kind));
      if (app.critical) badges.appendChild(makeBadge("Critica", "danger"));
      if (app.managed) badges.appendChild(makeBadge("Gestita", "managed"));
      body.append(name, pkg, badges);

      if (app.critical && app.reason) {
        const reason = document.createElement("div");
        reason.className = "reason";
        reason.textContent = app.reason;
        body.appendChild(reason);
      }

      const button = document.createElement("button");
      button.className = `toggle ${app.state === "active" ? "freeze" : "thaw"}`;
      button.textContent = app.state === "active" ? "Congela" : "Riattiva";
      button.addEventListener("click", () => toggleApp(app, button));

      card.append(avatar, body, button);
      list.appendChild(card);
    });
  }

  function confirmAction(app) {
    return new Promise(resolve => {
      pendingResolve = resolve;
      const freezing = app.state === "active";
      $("modalTitle").textContent = freezing ? `Congelare ${app.name}?` : `Riattivare ${app.name}?`;
      $("modalText").textContent = freezing
        ? `${app.pkg} verrà disabilitata per l'utente principale. APK, dati e impostazioni resteranno intatti.`
        : `${app.pkg} tornerà disponibile senza reinstallazione.`;

      const risky = freezing && app.critical;
      $("modalRisk").style.display = risky ? "block" : "none";
      $("modalRisk").textContent = risky ? app.reason : "";
      $("ackLabel").classList.toggle("visible", risky);
      $("ack").checked = false;
      $("confirm").disabled = risky;
      $("confirm").classList.toggle("danger", risky);
      $("confirm").textContent = freezing ? "Congela" : "Riattiva";
      $("modalBackdrop").classList.add("open");
    });
  }

  function closeModal(result) {
    $("modalBackdrop").classList.remove("open");
    const resolve = pendingResolve;
    pendingResolve = null;
    if (resolve) resolve(result);
  }

  async function toggleApp(app, button) {
    const confirmed = await confirmAction(app);
    if (!confirmed) return;

    button.disabled = true;
    try {
      const target = app.state === "active" ? "freeze" : "thaw";
      const force = target === "freeze" && app.critical ? " ALLOW_CRITICAL" : "";
      await execKsu(`${MODULE} set ${shellQuote(app.pkg)} ${target}${force}`);
      showToast(target === "freeze" ? `${app.name} congelata` : `${app.name} riattivata`);
      await loadApps(false);
    } catch (error) {
      showToast(error.message || "Operazione non riuscita");
      button.disabled = false;
    }
  }

  async function loadApps(showLoader = true) {
    $("refresh").disabled = true;
    if (showLoader) {
      $("list").innerHTML = '<div class="loading"><div class="spinner"></div>Caricamento delle app…</div>';
    }

    try {
      const result = await execKsu(`${MODULE} list`);
      apps = parseList(result.stdout);
      apps.sort((a, b) => a.name.localeCompare(b.name, "it", { sensitivity: "base" }));
      render();
    } catch (error) {
      $("list").replaceChildren();
      const message = document.createElement("div");
      message.className = "empty";
      message.textContent = error.message || "Impossibile caricare le app.";
      $("list").appendChild(message);
    } finally {
      $("refresh").disabled = false;
    }
  }

  function showToast(message) {
    const toast = $("toast");
    toast.textContent = message;
    toast.classList.add("show");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.remove("show"), 2600);
  }

  $("search").addEventListener("input", event => {
    query = event.target.value;
    render();
  });

  document.querySelectorAll(".chip").forEach(chip => chip.addEventListener("click", () => {
    document.querySelectorAll(".chip").forEach(item => item.classList.remove("selected"));
    chip.classList.add("selected");
    filter = chip.dataset.filter;
    render();
  }));

  $("refresh").addEventListener("click", () => loadApps(true));
  $("ack").addEventListener("change", event => { $("confirm").disabled = !event.target.checked; });
  $("cancel").addEventListener("click", () => closeModal(false));
  $("confirm").addEventListener("click", () => closeModal(true));
  $("modalBackdrop").addEventListener("click", event => {
    if (event.target === $("modalBackdrop")) closeModal(false);
  });

  loadApps(true);
})();
