/* Day Book — one fun observance a day, 366 days a year. */

(function () {
  "use strict";

  var DAYS = window.OBSERVANCES;
  var MONTHS = ["January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"];
  var WEEKDAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
  var STORE = "daybook.saved";

  var el = {
    sheet:    document.getElementById("sheet-inner"),
    numeral:  document.getElementById("numeral"),
    month:    document.getElementById("month"),
    weekday:  document.getElementById("weekday"),
    stamp:    document.getElementById("stamp"),
    title:    document.getElementById("title"),
    blurb:    document.getElementById("blurb"),
    also:     document.getElementById("also-list"),
    ndc:      document.getElementById("src-ndc"),
    nt:       document.getElementById("src-nt"),
    picker:   document.getElementById("picker"),
    save:     document.getElementById("save"),
    savedRow: document.getElementById("saved"),
    savedList:document.getElementById("saved-list"),
    toast:    document.getElementById("toast")
  };

  var today = startOfDay(new Date());
  var current = new Date(today);

  function startOfDay(d) { return new Date(d.getFullYear(), d.getMonth(), d.getDate()); }
  function pad(n) { return n < 10 ? "0" + n : String(n); }
  function key(d) { return pad(d.getMonth() + 1) + "-" + pad(d.getDate()); }
  function iso(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()); }

  /* Feb 29 only exists in leap years; everything else resolves directly. */
  function entry(d) { return DAYS[key(d)] || DAYS["02-28"]; }

  function readSaved() {
    try { return JSON.parse(localStorage.getItem(STORE)) || []; }
    catch (e) { return []; }
  }
  function writeSaved(list) {
    try { localStorage.setItem(STORE, JSON.stringify(list)); }
    catch (e) { /* private browsing, blocked storage — the page still works */ }
  }

  function toast(msg) {
    el.toast.textContent = msg;
    el.toast.classList.add("show");
    clearTimeout(toast._t);
    toast._t = setTimeout(function () { el.toast.classList.remove("show"); }, 1600);
  }

  function render(animate) {
    var d = current;
    var k = key(d);
    var day = entry(d);
    var monthName = MONTHS[d.getMonth()];

    function paint() {
      el.numeral.textContent = d.getDate();
      el.month.textContent = monthName;
      el.weekday.textContent = sameDay(d, today)
        ? "Today · " + WEEKDAYS[d.getDay()]
        : WEEKDAYS[d.getDay()] + ", " + d.getFullYear();
      el.stamp.textContent = day.e;
      el.title.textContent = day.name;
      el.blurb.textContent = day.blurb;

      el.also.textContent = "";
      day.also.forEach(function (name) {
        var li = document.createElement("li");
        li.textContent = name;
        el.also.appendChild(li);
      });

      var slug = monthName.toLowerCase();
      el.ndc.href = "https://nationaldaycalendar.com/" + slug + "/" + d.getDate();
      el.nt.href = "https://nationaltoday.com/" + slug + "-" + d.getDate() + "/";

      el.picker.value = iso(d);
      document.title = day.name + " — Day Book";

      var saved = readSaved().indexOf(k) !== -1;
      el.save.setAttribute("aria-pressed", saved ? "true" : "false");
      el.save.textContent = saved ? "★ Saved" : "☆ Save";
    }

    if (!animate) { paint(); renderSaved(); return; }

    el.sheet.classList.add("leaving");
    setTimeout(function () {
      paint();
      renderSaved();
      el.sheet.classList.remove("leaving");
      el.sheet.classList.add("arriving");
      setTimeout(function () { el.sheet.classList.remove("arriving"); }, 220);
    }, 130);
  }

  function sameDay(a, b) {
    return a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
      && a.getFullYear() === b.getFullYear();
  }

  function renderSaved() {
    var list = readSaved();
    el.savedRow.hidden = list.length === 0;
    el.savedList.textContent = "";
    list.slice().sort().forEach(function (k) {
      var parts = k.split("-");
      var b = document.createElement("button");
      b.type = "button";
      b.textContent = MONTHS[+parts[0] - 1].slice(0, 3) + " " + (+parts[1]) + " · " + DAYS[k].e;
      b.title = DAYS[k].name;
      b.addEventListener("click", function () { goToKey(k); });
      el.savedList.appendChild(b);
    });
  }

  function go(deltaDays) {
    current = new Date(current.getFullYear(), current.getMonth(), current.getDate() + deltaDays);
    render(true);
  }

  function goToKey(k) {
    var parts = k.split("-");
    var year = today.getFullYear();
    if (k === "02-29" && new Date(year, 1, 29).getMonth() !== 1) {
      /* nearest leap year, so Feb 29 lands on a real square */
      while (new Date(year, 1, 29).getMonth() !== 1) year++;
    }
    current = new Date(year, +parts[0] - 1, +parts[1]);
    render(true);
  }

  document.getElementById("prev").addEventListener("click", function () { go(-1); });
  document.getElementById("next").addEventListener("click", function () { go(1); });

  document.getElementById("today").addEventListener("click", function () {
    current = new Date(today);
    render(true);
  });

  document.getElementById("random").addEventListener("click", function () {
    var keys = Object.keys(DAYS);
    var k = keys[Math.floor(Math.random() * keys.length)];
    while (k === key(current)) k = keys[Math.floor(Math.random() * keys.length)];
    goToKey(k);
  });

  el.picker.addEventListener("change", function () {
    var parts = el.picker.value.split("-");
    if (parts.length !== 3) return;
    current = new Date(+parts[0], +parts[1] - 1, +parts[2]);
    render(true);
  });

  el.save.addEventListener("click", function () {
    var k = key(current);
    var list = readSaved();
    var i = list.indexOf(k);
    if (i === -1) { list.push(k); toast("Saved to your list"); }
    else { list.splice(i, 1); toast("Removed"); }
    writeSaved(list);
    render(false);
  });

  document.getElementById("copy").addEventListener("click", function () {
    var d = current, day = entry(d);
    var text = MONTHS[d.getMonth()] + " " + d.getDate() + " is " + day.name + ". " + day.blurb;
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(
        function () { toast("Copied"); },
        function () { toast("Copy blocked by your browser"); }
      );
    } else {
      toast("Copy blocked by your browser");
    }
  });

  document.addEventListener("keydown", function (e) {
    if (e.metaKey || e.ctrlKey || e.altKey) return;
    var t = e.target.tagName;
    if (t === "INPUT" || t === "TEXTAREA") return;
    if (e.key === "ArrowLeft") { go(-1); }
    else if (e.key === "ArrowRight") { go(1); }
    else if (e.key === "t" || e.key === "T") { current = new Date(today); render(true); }
    else if (e.key === "r" || e.key === "R") { document.getElementById("random").click(); }
  });

  render(false);
})();
