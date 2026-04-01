/**
 * @file
 * Initialises iframe-resizer on CS109 lab embed iframes.
 */
(function (Drupal) {
  'use strict';

  /**
   * Behavior: initialise iframeResizer after the DOM is ready.
   *
   * iframeResizer requires the content window to load
   * iframeResizer.contentWindow.min.js. The Shiny app.R must include:
   *   tags$script(src = "https://cdn.jsdelivr.net/npm/iframe-resizer@4.3.9/js/iframeResizer.contentWindow.min.js")
   */
  Drupal.behaviors.cs109LabEmbed = {
    attach: function (context) {
      const iframes = context.querySelectorAll
        ? context.querySelectorAll('iframe[data-lab-iframe]')
        : [];

      if (iframes.length === 0) {
        return;
      }

      if (typeof iFrameResize === 'undefined') {
        console.warn('cs109_labs: iframeResizer not loaded, skipping resize init.');
        return;
      }

      iFrameResize(
        {
          log: false,
          checkOrigin: false,
          minHeight: 600,
          scrolling: 'omit',
          warningTimeout: 10000,
        },
        'iframe[data-lab-iframe]'
      );
    },
  };
})(Drupal);
