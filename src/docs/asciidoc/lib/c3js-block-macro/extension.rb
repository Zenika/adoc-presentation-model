require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'

include Asciidoctor

# A block macro that embeds a Chart into the output document
#
# Usage
#
#   chart::sample.csv[line,800,500]
#
class C3jsBlockMacro < Extensions::BlockMacroProcessor
  use_dsl
  named :chart
  name_positional_attributes 'type'

  def process(parent, target, attrs)
    data_path = parent.normalize_asset_path(target, 'target')
    read_data = parent.read_asset(data_path, warn_on_failure: true, normalize: true)
    unless read_data.nil? || read_data.empty?
      raw_data = PlainRubyCSV.parse(read_data)
      html = C3jsChartBuilder.chart raw_data, attrs
      create_pass_block parent, html, attrs, subs: nil
    end
  end

end

class C3jsBlockProcessor < Extensions::BlockProcessor
  use_dsl
  named :chart
  on_context :literal
  name_positional_attributes 'type'
  parse_content_as :raw

  def process(parent, reader, attrs)
    raw_data = PlainRubyCSV.parse(reader.source)
    html = C3jsChartBuilder.chart raw_data, attrs
    create_pass_block parent, html, attrs, subs: nil
  end
end

class C3jsAssetsDocinfoProcessor < Extensions::DocinfoProcessor
  use_dsl
  #at_location :head

  def process doc
    %(
      <link rel="stylesheet" href="lib/c3.v0-6-11.min.css">
      <script src="lib/d3.v5-7-0.min.js" charset="utf-8"></script>
      <script src="lib/c3.v0-6-11.min.js"></script>
    )
  end
end

class C3jsChartBuilder

  # type = line : line/spline/step/area/area-spline/area-step/bar/scatter/pie/donut/gauge
  # height = 500 : whole chart height in pixels
  # width = 1000 : whole chart width in pixels
  # data-labels = false : Show labels on each data points.
  # x-type = indexed : timeseries/category/indexed
  # x-tick-angle = 0 : Rotate x axis tick text.
  # x-label = undefined : label of x axis
  # y-label = undefined : label of y axis
  # y-range = undefined_undefined : y axis min and max values separated by '_'
  # horizontal = false : rotate x & y
  # order = desc : desc/asc/null
  # legend = bottom : legend position bottom/right/inset

  def self.chart(raw_data, attrs)

    # plain ruby random
    chart_id = 'c3js' + (0...8).map { (65 + rand(26)).chr }.join

    # extract attributes/parameters
    type = attrs['type']
    height = (attrs.key? 'height') ? attrs['height'] : '500'
    width = (attrs.key? 'width') ? attrs['width'] : '1000'
    horizontal = (attrs.key? 'horizontal') ? attrs['horizontal'] : 'false'
    axis_x_type = (attrs.key? 'x-type') ? attrs['x-type'] : 'indexed'
    axis_x_text_angle = (attrs.key? 'x-tick-angle') ? attrs['x-tick-angle'] : '0'
    axis_x_label = (attrs.key? 'x-label') ? "'" + attrs['x-label'] + "'" : 'undefined'
    axis_y_label = (attrs.key? 'y-label') ? "'" + attrs['y-label'] + "'" : 'undefined'
    data_labels = (attrs.key? 'data-labels') ? attrs['data-labels'] : 'false'
    order = (attrs.key? 'order') ? attrs['order'] : 'desc'
    y_range = ((attrs.key? 'y-range') ? attrs['y-range'] : 'undefined_undefined').split("_")
    legend = (attrs.key? 'legend') ? attrs['legend'] : 'bottom'

    x_data = (axis_x_type == 'category') ? 'x: \'x\',' : ''

    # create the JS string
    %(
      <div id="#{chart_id}"></div>
      <script type="text/javascript">
      c3.generate({
        bindto: '##{chart_id}',
        size: { height: #{height}, width: #{width} },
        data: {
          #{x_data}
          columns: #{raw_data.to_s},
          type: '#{type}',
          labels: #{data_labels},
          order: '#{order}'
        },
        axis: {
          rotated: #{horizontal},
          x: {
            type: '#{axis_x_type}',
            tick: {
              rotate: #{axis_x_text_angle},
              multiline: false
            },
            label: #{axis_x_label}
          },
          y: {
            min: #{y_range[0]},
            max: #{y_range[1]},
            label: #{axis_y_label}
          }
        },
        legend: { position: '#{legend}' },
        color: {
              pattern: ['#8DBF44','#555555','#53A3DA','#D6D6B1','#B11E3E','#888888','#FFE119','#000075','#E8575C','#56A29A']
          }
        });
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
