# -*- coding: utf-8 -*-
# study.urls
# 

from kay.routing import (
  ViewGroup, Rule #@UnresolvedImport
)

view_groups = [
  ViewGroup(
    Rule('/', endpoint='index', view='study.views.index'),
    Rule('/gateway', endpoint='gateway', view = 'study.views.gateway'),
    Rule('/GFGAEStudy.html', endpoint='redirectIndex', view = 'study.views.redirectIndex'),
    Rule('/crossdomain.xml', endpoint='crossdomain', view='study.views.crossdomain'),
  )
]

