require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'

include Asciidoctor
#
# A block macro that generate a word cloud into the output document
#
# DISCLAMER : most of the code is mostly a blind copy from chart-block-macro. This need to be cleaned someday
#
class CloudBlockMacro < Extensions::BlockMacroProcessor
  use_dsl
  named :cloud
  name_positional_attributes 'class'

  def process(parent, target, attrs)
    data_path = parent.normalize_asset_path(target, 'target')
    read_data = parent.read_asset(data_path, warn_on_failure: true, normalize: true)
    unless read_data.nil? || read_data.empty?
      raw_data = PlainRubyCSV.parse(read_data)
      html = CloudBuilder.drawCloud raw_data, attrs
      create_pass_block parent, html, attrs, subs: nil
    end
  end

end

class CloudBlockProcessor < Extensions::BlockProcessor
  use_dsl
  named :cloud
  on_context :literal
  name_positional_attributes 'class'
  parse_content_as :raw

  def process(parent, reader, attrs)
    raw_data = PlainRubyCSV.parse(reader.source)
    html = CloudBuilder.drawCloud raw_data, attrs
    create_pass_block parent, html, attrs, subs: nil
  end
end

class CloudAssetsDocinfoProcessor < Extensions::DocinfoProcessor
  use_dsl
  #at_location :head

  def process doc
    %(
      <script src="lib/d3.v5-7-0.min.js" charset="utf-8"></script>
      <script src="lib/d3.layout.cloud.js"></script>
    )
  end
end

class CloudBuilder

  def self.drawCloud(raw_data, attrs)
    
    # only first line is useful, someday
    classes = (attrs.key? 'class') ? attrs['class'] : 'cloud'
    line = raw_data[0]

    # plain ruby random
    cloud_id = 'cloud' + (0...8).map { (65 + rand(26)).chr }.join

    # create the JS string
    %(
<div id="#{cloud_id}"></div>
<script type="text/javascript">
  wordCloud("##{cloud_id}","#{classes}", #{line.to_s});
</script>
    )
    end

end

class PlainRubyCSV

  def self.parse(data)
    result = []
    data.each_line do |line|
      line_chomp = line.chomp
      result.push(line_chomp.split(','))
    end
    result
  end

  def self.read(filename)
    result = []
    File.open(filename).each do |line|
      line_chomp = line.chomp
      result.push(line_chomp.split(','))
    end
    result
  end
end
