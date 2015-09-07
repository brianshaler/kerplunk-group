_ = require 'lodash'
React = require 'react'

{DOM} = React

module.exports = React.createFactory React.createClass
  getInitialState: ->
    group: @props.group
    identities: @props.group.identities
    identityToAdd: null

  selectIdentityToAdd: (identity) ->
    @setState
      identityToAdd: identity

  addIdentity: (e) ->
    e.preventDefault()
    groupId = @props.group._id
    identityId = @state.identityToAdd._id
    url = "/admin/groups/#{groupId}/add/#{identityId}.json"
    @props.request.post url, {}, (err, data) =>
      console.log err if err
      newState =
        identityToAdd: {}
      if data.group
        newState.group = data.group
      if data.group.identities
        newState.identities = data.group.identities
      @setState newState

  removeIdentity: (identityId) ->
    (e) =>
      e.preventDefault()
      groupId = @props.group._id
      url = "/admin/groups/#{groupId}/remove/#{identityId}.json"
      @props.request.post url, {}, (err, data) =>
        console.log err if err
        newState = {}
        if data.group
          newState.group = data.group
        if data.group.identities
          newState.identities = data.group.identities
        @setState newState

  onUpdate: (obj) ->
    @setState obj

  render: ->
    identityInputPath = 'kerplunk-identity-autocomplete:input'
    IdentityInputComponent = @props.getComponent identityInputPath

    identityConfig = @props.globals.public.identity
    cardComponentPath = identityConfig.contactCardComponent ? identityConfig.defaultContactCard
    ContactCard = @props.getComponent cardComponentPath

    DOM.section
      className: 'content'
    ,
      DOM.h3 null, @props.group.name
      DOM.div null,
        _.map (@props.globals.public.editGroupComponents ? {}), (componentPath, key) =>
          Component = @props.getComponent componentPath
          Component _.extend {}, @props,
            key: "edit-group-#{key}"
            onUpdate: @onUpdate
        DOM.h3 null, 'Add Contacts'
        IdentityInputComponent _.extend {}, @props,
          onSelect: @selectIdentityToAdd
          identity: @state.identityToAdd
          omit: _.pluck @state.identities, '_id'
        if @state.identityToAdd
          DOM.a
            href: '#'
            onClick: @addIdentity
            className: 'btn btn-success'
          ,
            DOM.em className: 'glyphicon glyphicon-plus'
            ' Add'
        else
          null
      DOM.div null,
        DOM.h3 null, 'Members'
        _.map @state.identities, (identity) =>
          props = _.extend {}, @props,
            key: "group-#{@props.group._id}-#{identity._id}"
            identity: identity
          ContactCard props,
            DOM.div null,
              DOM.a
                onClick: @removeIdentity identity._id
                href: '#'
                className: 'btn btn-danger btn-sm'
              , 'remove'
