Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|

  apply =
    # Everything in _posts
    (doc.respond_to?(:collection) && doc.collection.label == "posts") ||
    # Generated changelogs
    doc.respond_to?(:path) && File.basename(doc.path) == "fafbeta.md" ||
    doc.respond_to?(:path) && File.basename(doc.path) == "fafdevelop.md"

  next unless apply

  # Match plain text segments and inline formatting tags without crossing arrows
  # (-&gt;), block elements, or links (such as PR links in prose).
  atom = '(?:[^<-]|-(?!&gt;)|<code(?:\s[^>]*)?>[^<]*<\/code>|<strong(?:\s[^>]*)?>[^<]*<\/strong>|<em(?:\s[^>]*)?>[^<]*<\/em>)'

  # Style individual stat changes first so stat bullets with nested lists keep
  # their .change/.old/.new classes instead of matching as category headers.
  doc.output.gsub!(
    /(<li(?:\s[^>]*)?>(?:\s*<p>)?\s*)(#{atom}+:\s)(#{atom}+?)\s-&gt;\s(#{atom}+?)(\s*(?:<\/p>|<ul|<\/li>))/,
    '\1<span class="change">\2</span><span class="old">\3</span> → <span class="new">\4</span>\5'
  )

  # Wrap category headers (such as weapon or upgrade names) that precede nested
  # stat changes, avoiding full sentences ending in a period.
  doc.output.gsub!(
    /(<li(?:\s[^>]*)?>(?:\s*<p>)?\s*)(#{atom}+?)(?<!\.)(\s*(?:<\/p>)?\s*<ul[^>]*>\s*<li(?:\s[^>]*)?>(?:\s*<p>)?\s*<span class="change">)/,
    '\1<span class="change-category">\2</span>\3'
  )

end