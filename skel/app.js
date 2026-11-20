/* Upgrade <time class="when"> from a plain date to "3 hours ago".
 * The server-rendered text is the fallback; a hover title keeps
 * the exact UTC time.  No dependencies. */
(function () {
	'use strict';
	var units = [
		['year', 365 * 24 * 3600], ['month', 30 * 24 * 3600],
		['week', 7 * 24 * 3600], ['day', 24 * 3600],
		['hour', 3600], ['minute', 60]
	];
	var rtf = null;
	try { rtf = new Intl.RelativeTimeFormat(undefined, { numeric: 'auto' }); }
	catch (e) { /* old browser: keep the static text */ }

	function relative(then, now) {
		var s = Math.round((then - now) / 1000);
		if (Math.abs(s) < 45) { return rtf.format(0, 'second'); }
		for (var i = 0; i < units.length; i++) {
			if (Math.abs(s) >= units[i][1]) {
				return rtf.format(Math.round(s / units[i][1]), units[i][0]);
			}
		}
		return rtf.format(Math.round(s / 60), 'minute');
	}

	function tick() {
		var now = Date.now();
		var els = document.querySelectorAll('time.when[datetime]');
		for (var i = 0; i < els.length; i++) {
			var t = Date.parse(els[i].getAttribute('datetime'));
			if (!isNaN(t)) { els[i].textContent = relative(t, now); }
		}
	}

	if (!rtf) { return; }
	tick();
	setInterval(tick, 60 * 1000);
})();
