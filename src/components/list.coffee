_ = require 'lodash'
React = require 'react'

{DOM} = React

module.exports = React.createFactory React.createClass
  getInitialState: ->
    groups: @props.groups

  createGroup: (e) ->
    e.preventDefault()
    el = React.findDOMNode(@refs.newGroupName)
    url = '/admin/groups/create.json'
    opt =
      name: el.value
    @props.request.post url, opt, (err, data) =>
      if data.group
        @setState
          groups: [data.group].concat @state.groups
      console.log 'new group', el.value, data

  render: ->
    DOM.section
      className: 'content'
    ,
      DOM.div null,
        DOM.form
          onSubmit: @createGroup
        ,
          DOM.input
            ref: 'newGroupName'
            placeholder: 'Group Name'
          DOM.a
            onClick: @createGroup
            href: '#'
            className: 'btn btn-success'
          ,
            DOM.em className: 'glyphicon glyphicon-plus'
            'Create Group'
      _.map @state.groups, (group) =>
        DOM.div
          key: group._id
        ,
          DOM.h3 null,
            DOM.a
              onClick: @props.pushState
              href: "/admin/groups/#{group._id}/edit"
            , group.name
          DOM.p null,
            group.identities.length
            ' contact'
            ('s' if group.identities.length != 1)
