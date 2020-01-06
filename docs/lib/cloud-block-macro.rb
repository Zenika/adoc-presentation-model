RUBY_ENGINE == 'opal' ? (require 'cloud-block-macro/extension') : (require_relative 'cloud-block-macro/extension')

Extensions.register do
  if document.basebackend? 'html'
    block_macro CloudBlockMacro
    block CloudBlockProcessor
    docinfo_processor CloudAssetsDocinfoProcessor
  end
end
