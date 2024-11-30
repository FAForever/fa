---
layout: page
title: Changelogs
has_children: true
permalink: /changelog
nav_order: 8
---

# Overview of game patches

## Deployment branches

<ul>
  <li>
    <a class="preview-title" href="{{ 'changelog/fafbeta' | relative_url }}">FAF Beta Balance</a>
  </li>
  <li>
    <a class="preview-title" href="{{ 'changelog/fafdevelop' | relative_url }}">FAF Develop</a>
  </li>
</ul>

## Past game patches

<ul>
  {% assign last_year = false %}
  {% for post in site.posts %}

    {% assign current_year = post.date | date: "%Y" %}
    {% if last_year != current_year %}
      {% assign last_year = current_year %}
      <h2 id="{{current_year}}">
        Year {{ current_year }}
      </h2>
    {% endif %}

    <li>
      <a class="preview-title" href="{{ post.url | relative_url }}">{{ post.title }}</a>
      <span>({{ post.date | date: "%b %d" }})</span>
    </li>
{% endfor %}
</ul>
