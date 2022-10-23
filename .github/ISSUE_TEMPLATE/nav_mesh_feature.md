---
name: Navigational mesh feature request
about: To discuss the request of implementing queries for the navigational mesh, 
title: ''
labels: 'status: novel issue, area: nav-mesh'
assignees: ''

---

## Describe the query

A clear and concise description of what the query is. This includes the parameters and the expected output. Make sure to include the types. As an example:

```lua
---@param layer String
---@param origin Vector
---@param destination Vector
---@return boolean
function CanPathTo(layer, origin, destination)

end
```

## Visualize the query
Screenshots with drawings on top of it to help solidify the expectation of the query. As an example:

```lua
The idea is that you can generate a path that can help the AI to path from a specific vector. A simple comparison is finding a path from `a` to `b`, via `c`. To make it more visual:
```

![image](https://user-images.githubusercontent.com/15778155/196362165-d146d149-b2e5-424d-80c6-ef9e61f08b58.png)

Note that you can copy/paste images directly into Github. 

Not all requests are easy to draw up, therefore this section is optional. 

## True / false positives

Some queries can be ambigious. One example is chokepoints. What is considered a choke point, and what is not? We need this data to help create the algorithm, while at the same time being able to confirm that it is well-balanced in making the decisions. This usually involves a lot of screenshots with positive output (it is a chokepoint) and negative output (it is not a choke point).

Note that you can copy/paste images directly into Github. 

Not all requests are easy to draw up, therefore this section is optional. 

## Additional context

Add any other context about the query here.

_This query request will be read by people that are unable to look into your thoughts - this issue is all they have to determine the viability of the query. The more precise your description, the easier it becomes for us to help you._
