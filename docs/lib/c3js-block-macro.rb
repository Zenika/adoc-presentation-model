RUBY_ENGINE == 'opal' ? (require 'c3js-block-macro/extension') : (require_relative 'c3js-block-macro/extension')

# see http://www.jsgraphs.com/ for a comparison of JavaScript charting libraries

Extensions.register do
  if document.basebackend? 'html'
    block_macro C3jsBlockMacro
    block C3jsBlockProcessor
    docinfo_processor C3jsAssetsDocinfoProcessor
  end
end
