/*globals $ CodeMirror controllers model alert DEVELOPMENT: true */
/*jshint boss:true */

DEVELOPMENT = true;

var ROOT = "",
    ROOT_REGEX = new RegExp(ROOT + "/.*$"),
    ACTUAL_ROOT = document.location.pathname.replace(ROOT_REGEX, '') || ".";

(function() {

  var interactiveDefinitionLoaded = $.Deferred(),
      windowLoaded = $.Deferred(),

      selectInteractive = document.getElementById('select-interactive'),
      exportData = document.getElementById('export-data'),
      showData = document.getElementById('show-data'),
      exportedData = document.getElementById('exported-data'),

      $exportedData = $("exported-data"),
      editor,
      controller,
      indent = 2,
      interactiveUrl,
      interactive,
      hash,
      jsonModelPath, contentItems, mmlPath, cmlPath,
      viewType,
      dgPaylod, dgUrl,
      appletString, applet,
      nlObjPanel, nlObjWorkspace, nlObjWorld,
      nlObjProgram, nlObjObserver, nlObjGlobals,
      nlGlobals,
      clearDataReady;

  if (!document.location.hash) {
    if (selectInteractive) {
      selectInteractiveHandler();
    } else {
      document.location.hash = '#interactives/visual-airbags-v26.v0.json';
    }
  }

  if (hash = document.location.hash) {
    interactiveUrl = hash.substr(1, hash.length);

    $.get(interactiveUrl).done(function(results) {
      if (typeof results === 'string') results = JSON.parse(results);
      interactive = results;

      // Use the presense of selectInteractive as a proxy indicating that the
      // rest of the elements on the non-iframe-embeddable version of the page
      // are present and should be setup.
      if (selectInteractive) {
        setupFullPage();
      } else {
        viewType = 'interactive-iframe';
      }

      if (interactive.model.modelType == "netlogo-applet") {
        appletString =
          ['<applet id="netlogo-applet" code="org.nlogo.lite.Applet"',
          '     width="' + interactive.model.viewOptions.appletDimensions.width + '" height="' + interactive.model.viewOptions.appletDimensions.height + '" MAYSCRIPT="true"',
          '     archive="' + ACTUAL_ROOT + '/netlogo/NetLogoLite.jar"',
          '     MAYSCRIPT="true">',
          '  <param name="DefaultModel" value="' + interactive.model.url + '"/>',
          '  <param name="MAYSCRIPT" value="true"/>',
          '  Your browser is completely ignoring the applet tag!',
          '</applet>'].join('\n');

        document.getElementById("applet-container").innerHTML = appletString;
        applet = document.getElementById('netlogo-applet');
        applet.ready = false;
        applet.checked_more_than_once = false;
        var self = this;
        window.setTimeout(appletReady, 250);
      }
      interactiveDefinitionLoaded.resolve();
    });
  }

  function appletReady() {
    var globalsStr;
    applet.ready = false;
    try {
      nlObjPanel     = applet.panel();                                           // org.nlogo.lite.Applet object
      nlObjWorkspace = nlObjPanel.workspace();                                 // org.nlogo.lite.LiteWorkspace
      nlObjWorld     = nlObjWorkspace.org$nlogo$lite$LiteWorkspace$$world;     // org.nlogo.agent.World
      nlObjProgram   = nlObjWorld.program();                                   // org.nlogo.api.Program
      nlObjObserver  = nlObjWorld.observer();
      nlObjGlobals   = nlObjProgram.globals();
      globalsStr = nlObjGlobals.toString();
      nlGlobals = globalsStr.substr(1, globalsStr.length-2).split(",").map(function(e) { return stripWhiteSpace(e); });
      if (nlGlobals.length > 1) {
        applet.ready = true;
      }
    } catch (e) {
      // applet is not ready
    }

    if (applet.ready) {
      window.setInterval(buttonStatusCallback, 250);
    } else {
      applet.checked_more_than_once = window.setTimeout(appletReady, 250);
    }
    return applet.ready;
  }

  function buttonStatusCallback() {
    var export_button = exportData,
        show_button = showData;

    try {
      if (nlDataAvailable()) {
        export_button.disabled = false;
        show_button.disabled = false;
      } else {
        export_button.disabled = true;
        show_button.disabled = true;
      }
    } catch (e) {
      // Do nothing--we'll try again in the next timer interval.
    }
  }

  $(window).load(function() {
    windowLoaded.resolve();
  });

  $.when(interactiveDefinitionLoaded, windowLoaded).done(function(results) {
    // controller = controllers.interactivesController(interactive, '#interactive-container', viewType);
  });

  $(window).bind('hashchange', function() {
    if (document.location.hash !== hash) {
      location.reload();
    }
  });

  function stripWhiteSpace(str) {
    return str.replace(/^\s\s*/, '').replace(/\s\s*$/, '');
  }

  function nlCmdExecute(cmd) {
    nlObjPanel.commandLater(cmd);
  }

  function nlReadGlobal(global) {
    return nlObjObserver.getVariable(nlGlobals.indexOf(global));
  }

  function nlDataExportModuleAvailable() {
    return this.nlReadGlobal("DATA-EXPORT:MODULE-AVAILABLE");
  }

  function nlDataAvailable() {
    return nlReadGlobal("DATA-EXPORT:DATA-AVAILABLE?");
  }

  function nlDataReady() {
    return nlReadGlobal("DATA-EXPORT:DATA-READY?");
  }

  function getExportedData() {
    return nlReadGlobal("DATA-EXPORT:MODEL-DATA");
  }

  function exportDataHandler() {
    var startTime,
        elapsedTime = 0;
    nlCmdExecute("data-export:make-model-data");
    // startTime = Date.now();
    // // for some reason we have to wait here 200ms
    // while(elapsedTime < 200) {
    //   elapsedTime = Date.now() - startTime;
    // }
    clearDataReady = window.setInterval(exportDataReadyCallback, 200);
  }

  function exportDataReadyCallback() {
    var modelData,
        modelDataStr,
        dgExportDone = nlDataReady();
    if (dgExportDone) {
      clearInterval(clearDataReady);
      modelData = JSON.parse(getExportedData());
      modelDataStr = JSON.stringify(modelData, null, 2);
      if (exportedData) {
        exportedData.textContent = modelDataStr;
        if (editor) {
          editor.setValue(modelDataStr);
        }
      } else {
        console.log(modelData);
      }
    }
  }

  if (exportData) {
    exportData.onclick = exportDataHandler;
  }

  //
  // The following functions are only used when rendering the
  // non-embeddable Interactive page
  //
  function selectInteractiveHandler() {
    document.location.hash = '#' + selectInteractive.value;
  }

  function setupFullPage() {
    selectInteractive.value = interactiveUrl;
    setupCodeEditor();
    selectInteractive.onchange = selectInteractiveHandler;
  }

  //
  // Interactive Code Editor
  //
  function setupCodeEditor() {
    var foldFunc = CodeMirror.newFoldFunction(CodeMirror.braceRangeFinder);
    $exportedData.text("");
    if (!editor) {
      editor = CodeMirror.fromTextArea(exportedData, {
        mode: { name: "javascript", json: true },
        indentUnit: indent,
        lineNumbers: true,
        lineWrapping: false,
        matchBrackets: true,
        autoCloseBrackets: true,
        collapseRange: true,
        onGutterClick: foldFunc
      });
    }
  }

  // startButtonStatusCallback();

}());
