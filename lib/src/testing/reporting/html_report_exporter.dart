import 'dart:convert';

import '../screenshot/scenario_screenshot_service.dart';
import 'scenario_test_report.dart';

/// Exporter that compiles a [ScenarioTestReport] into a self-contained,
/// interactive HTML report with embedded Base64 screenshots, zero external CDN dependencies,
/// and responsive developer-grade styling.
class HtmlReportExporter {
  /// Creates an [HtmlReportExporter].
  const HtmlReportExporter();

  /// Compiles [report] into a standalone HTML string.
  String export(ScenarioTestReport report) {
    final buffer = StringBuffer();

    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="en">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln(
        '  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>${_escape(report.title)}</title>');
    buffer.writeln('  <style>');
    buffer.writeln(_generateCss());
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    // Header
    buffer.writeln('  <header class="header">');
    buffer.writeln('    <div class="header-content">');
    buffer.writeln('      <div class="logo-area">');
    buffer.writeln('        <span class="logo-icon">&#x26A1;</span>');
    buffer.writeln('        <div>');
    buffer.writeln('          <h1>${_escape(report.title)}</h1>');
    buffer.writeln(
        '          <p class="subtitle">Generated on ${report.startTime.toLocal().toString().split('.')[0]} &bull; Total Duration: ${report.duration.inMilliseconds}ms</p>');
    buffer.writeln('        </div>');
    buffer.writeln('      </div>');
    buffer.writeln(
        '      <div class="header-status ${report.isSuccess ? 'status-pass' : 'status-fail'}">');
    buffer.writeln(
        '        ${report.isSuccess ? 'ALL TESTS PASSED' : '${report.failedCount} TESTS FAILED'}');
    buffer.writeln('      </div>');
    buffer.writeln('    </div>');
    buffer.writeln('  </header>');

    buffer.writeln('  <main class="container">');

    // KPI Cards
    buffer.writeln('    <section class="kpi-grid">');
    buffer.writeln('      <div class="kpi-card">');
    buffer.writeln('        <div class="kpi-label">Total Tests</div>');
    buffer.writeln('        <div class="kpi-value">${report.totalTests}</div>');
    buffer.writeln('      </div>');
    buffer.writeln('      <div class="kpi-card kpi-pass">');
    buffer.writeln('        <div class="kpi-label">Passed</div>');
    buffer
        .writeln('        <div class="kpi-value">${report.passedCount}</div>');
    buffer.writeln('      </div>');
    buffer.writeln('      <div class="kpi-card kpi-fail">');
    buffer.writeln('        <div class="kpi-label">Failed</div>');
    buffer
        .writeln('        <div class="kpi-value">${report.failedCount}</div>');
    buffer.writeln('      </div>');
    buffer.writeln('      <div class="kpi-card kpi-skip">');
    buffer.writeln('        <div class="kpi-label">Skipped</div>');
    buffer
        .writeln('        <div class="kpi-value">${report.skippedCount}</div>');
    buffer.writeln('      </div>');
    buffer.writeln('      <div class="kpi-card">');
    buffer.writeln('        <div class="kpi-label">Success Rate</div>');
    buffer.writeln(
        '        <div class="kpi-value">${report.successRate.toStringAsFixed(1)}%</div>');
    buffer.writeln('      </div>');
    buffer.writeln('      <div class="kpi-card">');
    buffer.writeln('        <div class="kpi-label">Total Duration</div>');
    buffer.writeln(
        '        <div class="kpi-value">${(report.duration.inMilliseconds / 1000).toStringAsFixed(2)}s</div>');
    buffer.writeln('      </div>');
    buffer.writeln('    </section>');

    // Environment section if present
    if (report.environment.isNotEmpty) {
      buffer.writeln('    <section class="section environment-card">');
      buffer.writeln('      <h3>Environment Diagnostics</h3>');
      buffer.writeln('      <div class="env-badges">');
      for (final entry in report.environment.entries) {
        buffer.writeln(
            '        <span class="env-badge"><strong>${_escape(entry.key)}:</strong> ${_escape(entry.value.toString())}</span>');
      }
      buffer.writeln('      </div>');
      buffer.writeln('    </section>');
    }

    // Results by Summary / Screen
    buffer.writeln('    <section class="section">');
    buffer.writeln('      <h2>Test Results</h2>');

    for (final summary in report.summaries) {
      final screenLabel = summary.screenName ?? 'Functionality Tests';
      buffer.writeln('      <div class="suite-card">');
      buffer.writeln('        <div class="suite-header">');
      buffer.writeln('          <div class="suite-title">');
      buffer.writeln('            <h3>${_escape(screenLabel)}</h3>');
      buffer.writeln(
          '            <span class="mode-badge">${summary.executionMode.name}</span>');
      buffer.writeln('          </div>');
      buffer.writeln('          <div class="suite-meta">');
      buffer.writeln(
          '            <span>${summary.passedCount}/${summary.totalTests} Passed</span> &bull;');
      buffer.writeln(
          '            <span>${summary.duration.inMilliseconds}ms</span>');
      buffer.writeln('          </div>');
      buffer.writeln('        </div>');

      buffer.writeln('        <div class="test-list">');
      for (final test in summary.results) {
        final statusClass = test.isPassed
            ? 'status-pass'
            : (test.isFailed ? 'status-fail' : 'status-skip');
        buffer.writeln(
            '          <details class="test-details" ${test.isFailed ? 'open' : ''}>');
        buffer.writeln('            <summary class="test-summary">');
        buffer.writeln('              <div class="test-info">');
        buffer.writeln(
            '                <span class="status-pill $statusClass">${test.status.name.toUpperCase()}</span>');
        buffer.writeln(
            '                <span class="test-name">${_escape(test.name)}</span>');
        if (test.group != null) {
          buffer.writeln(
              '                <span class="group-badge">${_escape(test.group!)}</span>');
        }
        buffer.writeln('              </div>');
        buffer.writeln(
            '              <div class="test-timing">${test.duration.inMilliseconds}ms</div>');
        buffer.writeln('            </summary>');

        buffer.writeln('            <div class="test-body">');

        // Error message if failed
        if (test.isFailed && test.errorMessage != null) {
          buffer.writeln('              <div class="error-box">');
          buffer.writeln(
              '                <strong>Error:</strong> ${_escape(test.errorMessage!)}');
          if (test.stackTrace != null) {
            buffer.writeln(
                '                <pre class="stack-trace">${_escape(test.stackTrace.toString())}</pre>');
          }
          buffer.writeln('              </div>');
        }

        // Steps List
        if (test.stepResults.isNotEmpty) {
          buffer.writeln(
              '              <h4>Execution Steps (${test.stepResults.length})</h4>');
          buffer.writeln('              <div class="steps-table">');
          for (int i = 0; i < test.stepResults.length; i++) {
            final step = test.stepResults[i];
            final stepStatusClass = step.isPassed
                ? 'status-pass'
                : (step.isFailed ? 'status-fail' : 'status-skip');
            buffer.writeln('                <div class="step-row">');
            buffer.writeln(
                '                  <span class="step-num">${i + 1}</span>');
            buffer.writeln(
                '                  <span class="status-pill $stepStatusClass">${step.status.name}</span>');
            buffer.writeln(
                '                  <span class="step-desc">${_escape(step.description)}</span>');
            buffer.writeln(
                '                  <span class="step-dur">${step.duration.inMilliseconds}ms</span>');
            buffer.writeln('                </div>');
          }
          buffer.writeln('              </div>');
        }

        // Assertions
        if (test.assertions.isNotEmpty) {
          buffer.writeln(
              '              <h4>Assertions (${test.assertions.length})</h4>');
          buffer.writeln('              <ul class="assertions-list">');
          for (final a in test.assertions) {
            final aClass = a.isSuccess ? 'assert-pass' : 'assert-fail';
            buffer.writeln('                <li class="$aClass">');
            buffer.writeln(
                '                  <strong>${a.isSuccess ? '&#x2714;' : '&#x2718;'}</strong> ${_escape(a.description)}');
            if (a.isFailure && a.failureMessage != null) {
              buffer.writeln(
                  '                  <div class="assert-fail-msg">${_escape(a.failureMessage!)}</div>');
            }
            buffer.writeln('                </li>');
          }
          buffer.writeln('              </ul>');
        }

        // Screenshots
        if (test.screenshots.isNotEmpty) {
          buffer.writeln(
              '              <h4>Captured Screenshots (${test.screenshots.length})</h4>');
          buffer.writeln('              <div class="screenshot-gallery">');
          for (final shot in test.screenshots) {
            final dataUrl =
                ScenarioScreenshotService.toBase64DataUrl(shot.bytes);
            buffer.writeln('                <div class="screenshot-item">');
            buffer.writeln(
                '                  <img src="$dataUrl" alt="${_escape(shot.name)}" onclick="openModal(\'$dataUrl\', \'${_escape(shot.name)}\')" />');
            buffer.writeln(
                '                  <div class="screenshot-caption">${_escape(shot.name)}</div>');
            buffer.writeln('                </div>');
          }
          buffer.writeln('              </div>');
        }

        // Logs
        if (test.logs.isNotEmpty) {
          buffer.writeln('              <details class="logs-details">');
          buffer.writeln(
              '                <summary>Execution Logs (${test.logs.length})</summary>');
          buffer.writeln(
              '                <pre class="logs-content">${test.logs.map(_escape).join('\n')}</pre>');
          buffer.writeln('              </details>');
        }

        buffer.writeln('            </div>'); // test-body
        buffer.writeln('          </details>'); // test-details
      }
      buffer.writeln('        </div>'); // test-list
      buffer.writeln('      </div>'); // suite-card
    }

    buffer.writeln('    </section>');
    buffer.writeln('  </main>');

    // Screenshot Modal
    buffer.writeln(
        '  <div id="imageModal" class="modal" onclick="closeModal()">');
    buffer.writeln('    <div class="modal-content">');
    buffer.writeln('      <img id="modalImg" src="" alt="Full Screenshot">');
    buffer.writeln('      <div id="modalCaption" class="modal-caption"></div>');
    buffer.writeln('    </div>');
    buffer.writeln('  </div>');

    // Modal JS
    buffer.writeln('  <script>');
    buffer.writeln('    function openModal(src, caption) {');
    buffer.writeln('      document.getElementById("modalImg").src = src;');
    buffer.writeln(
        '      document.getElementById("modalCaption").innerText = caption;');
    buffer.writeln(
        '      document.getElementById("imageModal").style.display = "flex";');
    buffer.writeln('    }');
    buffer.writeln('    function closeModal() {');
    buffer.writeln(
        '      document.getElementById("imageModal").style.display = "none";');
    buffer.writeln('    }');
    buffer.writeln('  </script>');

    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  static String _escape(String text) {
    return const HtmlEscape().convert(text);
  }

  String _generateCss() {
    return '''
      :root {
        --bg-main: #0f172a;
        --bg-card: #1e293b;
        --bg-inner: #0b1120;
        --border-color: #334155;
        --text-primary: #f8fafc;
        --text-secondary: #94a3b8;
        --accent: #38bdf8;
        --color-pass: #22c55e;
        --color-fail: #ef4444;
        --color-skip: #f59e0b;
      }
      * { box-sizing: border-box; margin: 0; padding: 0; }
      body {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
        background-color: var(--bg-main);
        color: var(--text-primary);
        line-height: 1.5;
        padding-bottom: 60px;
      }
      .header {
        background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
        border-bottom: 1px solid var(--border-color);
        padding: 24px 32px;
      }
      .header-content {
        max-width: 1200px;
        margin: 0 auto;
        display: flex;
        align-items: center;
        justify-content: space-between;
      }
      .logo-area { display: flex; align-items: center; gap: 16px; }
      .logo-icon { font-size: 32px; }
      h1 { font-size: 24px; font-weight: 700; color: #fff; }
      .subtitle { font-size: 13px; color: var(--text-secondary); margin-top: 4px; }
      .header-status {
        padding: 8px 16px;
        border-radius: 9999px;
        font-size: 13px;
        font-weight: 700;
        letter-spacing: 0.5px;
      }
      .container { max-width: 1200px; margin: 32px auto; padding: 0 24px; }
      .kpi-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
        gap: 16px;
        margin-bottom: 32px;
      }
      .kpi-card {
        background: var(--bg-card);
        border: 1px solid var(--border-color);
        border-radius: 8px;
        padding: 16px;
        text-align: center;
      }
      .kpi-label { font-size: 12px; color: var(--text-secondary); text-transform: uppercase; letter-spacing: 0.5px; }
      .kpi-value { font-size: 28px; font-weight: 800; margin-top: 6px; color: #fff; }
      .kpi-pass .kpi-value { color: var(--color-pass); }
      .kpi-fail .kpi-value { color: var(--color-fail); }
      .kpi-skip .kpi-value { color: var(--color-skip); }
      .section { margin-bottom: 32px; }
      h2 { font-size: 20px; font-weight: 600; margin-bottom: 16px; color: #f1f5f9; }
      h3 { font-size: 16px; font-weight: 600; color: #f8fafc; }
      h4 { font-size: 13px; font-weight: 600; color: var(--text-secondary); margin: 16px 0 8px 0; text-transform: uppercase; }
      .environment-card {
        background: var(--bg-card);
        border: 1px solid var(--border-color);
        border-radius: 8px;
        padding: 16px 20px;
        margin-bottom: 24px;
      }
      .env-badges { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 10px; }
      .env-badge {
        background: var(--bg-inner);
        border: 1px solid var(--border-color);
        padding: 4px 10px;
        border-radius: 4px;
        font-size: 12px;
        color: var(--text-secondary);
      }
      .suite-card {
        background: var(--bg-card);
        border: 1px solid var(--border-color);
        border-radius: 8px;
        margin-bottom: 20px;
        overflow: hidden;
      }
      .suite-header {
        background: #1e293b;
        border-bottom: 1px solid var(--border-color);
        padding: 14px 20px;
        display: flex;
        justify-content: space-between;
        align-items: center;
      }
      .suite-title { display: flex; align-items: center; gap: 12px; }
      .mode-badge {
        background: #334155;
        padding: 2px 8px;
        border-radius: 4px;
        font-size: 11px;
        color: var(--text-secondary);
        text-transform: uppercase;
      }
      .suite-meta { font-size: 13px; color: var(--text-secondary); }
      .test-list { padding: 8px; }
      .test-details {
        border-bottom: 1px solid #283548;
        padding: 4px 0;
      }
      .test-details:last-child { border-bottom: none; }
      .test-summary {
        list-style: none;
        cursor: pointer;
        padding: 10px 14px;
        border-radius: 6px;
        display: flex;
        justify-content: space-between;
        align-items: center;
        user-select: none;
      }
      .test-summary:hover { background: #26354a; }
      .test-info { display: flex; align-items: center; gap: 12px; }
      .test-name { font-size: 14px; font-weight: 500; }
      .group-badge {
        background: #334155;
        color: #94a3b8;
        font-size: 11px;
        padding: 2px 6px;
        border-radius: 4px;
      }
      .test-timing { font-size: 12px; color: var(--text-secondary); }
      .status-pill {
        padding: 2px 8px;
        border-radius: 4px;
        font-size: 11px;
        font-weight: 700;
        text-transform: uppercase;
      }
      .status-pass { background: rgba(34, 197, 94, 0.15); color: var(--color-pass); }
      .status-fail { background: rgba(239, 68, 68, 0.15); color: var(--color-fail); }
      .status-skip { background: rgba(245, 158, 11, 0.15); color: var(--color-skip); }
      .test-body {
        padding: 16px 20px;
        background: var(--bg-inner);
        border-radius: 6px;
        margin: 8px 14px;
      }
      .error-box {
        background: rgba(239, 68, 68, 0.1);
        border: 1px solid rgba(239, 68, 68, 0.3);
        border-radius: 6px;
        padding: 12px 16px;
        margin-bottom: 16px;
        color: #fca5a5;
        font-size: 13px;
      }
      .stack-trace {
        font-family: monospace;
        font-size: 11px;
        color: #f87171;
        margin-top: 8px;
        overflow-x: auto;
      }
      .steps-table { display: flex; flex-direction: column; gap: 4px; margin-bottom: 16px; }
      .step-row {
        display: flex;
        align-items: center;
        gap: 12px;
        font-size: 13px;
        padding: 6px 10px;
        background: #131c2e;
        border-radius: 4px;
      }
      .step-num { color: var(--text-secondary); font-size: 11px; width: 20px; }
      .step-desc { flex-grow: 1; }
      .step-dur { font-size: 11px; color: var(--text-secondary); }
      .assertions-list { list-style: none; margin-bottom: 16px; }
      .assertions-list li {
        font-size: 13px;
        padding: 6px 10px;
        border-radius: 4px;
        margin-bottom: 4px;
        background: #131c2e;
      }
      .assert-pass { color: #86efac; }
      .assert-fail { color: #fca5a5; }
      .assert-fail-msg { font-size: 12px; color: #ef4444; margin-top: 2px; }
      .screenshot-gallery { display: flex; flex-wrap: wrap; gap: 12px; margin-bottom: 16px; }
      .screenshot-item {
        width: 140px;
        border: 1px solid var(--border-color);
        border-radius: 6px;
        overflow: hidden;
        background: #0f172a;
        cursor: pointer;
        transition: transform 0.2s;
      }
      .screenshot-item:hover { transform: scale(1.04); }
      .screenshot-item img { width: 100%; height: 160px; object-fit: cover; display: block; }
      .screenshot-caption { font-size: 11px; color: var(--text-secondary); padding: 4px 6px; text-align: center; }
      .logs-details summary { cursor: pointer; font-size: 12px; color: var(--text-secondary); }
      .logs-content {
        font-family: monospace;
        font-size: 11px;
        color: #94a3b8;
        background: #090d16;
        padding: 10px;
        border-radius: 4px;
        margin-top: 6px;
        max-height: 180px;
        overflow-y: auto;
      }
      .modal {
        display: none;
        position: fixed;
        z-index: 9999;
        left: 0;
        top: 0;
        width: 100%;
        height: 100%;
        background-color: rgba(0, 0, 0, 0.85);
        align-items: center;
        justify-content: center;
      }
      .modal-content {
        max-width: 90%;
        max-height: 90%;
        text-align: center;
      }
      .modal-content img {
        max-width: 100%;
        max-height: 80vh;
        border-radius: 8px;
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.5);
      }
      .modal-caption { color: #fff; margin-top: 12px; font-size: 14px; font-weight: 600; }
    ''';
  }
}
