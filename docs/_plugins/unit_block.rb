module Jekyll
  class UnitBlock < Liquid::Block

    def initialize(tag_name, markup, tokens)
      super
      @unit_id = markup.strip
    end

    def render(context)
      name = super.strip

      <<~HTML
      <div class="unit-header" data-unit="#{@unit_id}">
        <img class="unit-icon"
             src="/assets/icons/#{@unit_id}.png">
        <span class="unit-name">#{name}</span>
      </div>
      HTML
    end
  end
end

Liquid::Template.register_tag('unit', Jekyll::UnitBlock)