const purgecss = require('@fullhuman/postcss-purgecss')

module.exports = {
  plugins: [
    require('autoprefixer'),
    purgecss({
      content: [
        './app/views/**/*.html.erb',
        './app/javascript/**/*.js',
      ],
      safelist: {
        // Dynamically built classes that don't appear literally in templates
        standard: [
          'badge-status-want-to-read',
          'badge-status-reading',
          'badge-status-finished',
          // Bootstrap JS-toggled states
          'show',
          'fade',
          'active',
          'disabled',
          'collapsing',
          'collapsed',
        ],
        // Keep any selector containing these class patterns (Bootstrap toggled states,
        // Turbo/Stimulus generated classes, FA utility classes)
        deep: [
          /^modal/,
          /^offcanvas/,
          /^tooltip/,
          /^popover/,
          /^carousel/,
        ],
      },
    }),
  ],
}
