module Jekyll
  class UnitBlock < Liquid::Block

    def initialize(tag_name, markup, tokens)
      super
      @unit_id = markup.strip
    end

    def render(context)
      name = super.strip

      icon_name =
        if @unit_id.start_with?("enhancements")
          "#{@unit_id}.png"
        else
          "#{@unit_id.upcase}_icon.png"
        end

      <<~HTML
      <div class="unit-header">
        <img class="unit-icon"
             src="/assets/icons/#{icon_name}">
        <span class="unit-name">#{name}</span>
      </div>
      HTML
    end
  end
end

Liquid::Template.register_tag('unit', Jekyll::UnitBlock)