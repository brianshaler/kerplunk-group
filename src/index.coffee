_ = require 'lodash'
Promise = require 'when'

GroupSchema = require './models/Group'

module.exports = (System) ->
  Group = System.registerModel 'Group', GroupSchema
  Identity = System.getModel 'Identity'

  getGroup = (nameOrId) ->
    Promise.promise (resolve, reject) ->
      Group
      .where
        _id: nameOrId
      .findOne()
      .then (group) ->
        resolve group
      .catch (err) ->
        reject err
    .catch (err) ->
      throw err unless err?.name == 'CastError'
      Group
      .where
        name: nameOrId
      .findOne()

  list = (req, res, next) ->
    Group
    .find (err, groups) ->
      return next err if err
      res.render 'list',
        groups: groups

  create = (req, res, next) ->
    return next new Error 'nope' unless req.body?.name
    {name} = req.body

    Group
    .where
      name: name
    .findOne (err, existingGroup) ->
      return next err if err
      return next new Error 'Name taken' if existingGroup?
      group = new Group
        name: name
        identities: []
      group.save (err) ->
        return next err if err
        res.send
          group: group

  edit = (req, res, next) ->
    Group
    .where
      _id: req.params.groupId
    .populate 'identities'
    .findOne (err, group) ->
      return next err if err
      return next() unless group
      res.render 'edit',
        group: group

  deleteGroup = (req, res, next) ->
    Group
    .where
      _id: req.params.groupId
    .remove (err) ->
      return next err if err
      res.redirect '/admin/groups'

  addIdentity = (req, res, next) ->
    Group
    .where
      _id: req.params.groupId
    .findOne (err, group) ->
      return next err if err
      return next() unless group
      group.identities.push req.params.identityId
      group.save (err) ->
        Group
        .where
          _id: req.params.groupId
        .populate 'identities'
        .findOne (err, group) ->
          return next err if err
          return next() unless group
          if req.params.format == 'json'
            res.send
              message: 'ok'
              group: group
          else
            res.redirect "/admin/groups/#{group._id}/edit"

  removeIdentity = (req, res, next) ->
    Group
    .where
      _id: req.params.groupId
    .findOne (err, group) ->
      return next err if err
      return next() unless group
      group.identities = _.filter group.identities, (identity) ->
        String(identity) != String(req.params.identityId)
      group.markModified 'identities'
      group.save (err) ->
        Group
        .where
          _id: req.params.groupId
        .populate 'identities'
        .findOne (err, group) ->
          return next err if err
          return next() unless group
          if req.params.format == 'json'
            res.send
              message: 'ok'
              group: group
          else
            res.redirect "/admin/groups/#{group._id}/edit"

  nav =
    All: '/admin/groups'

  routes:
    admin:
      '/admin/groups': 'list'
      '/admin/groups/create': 'create'
      '/admin/groups/:groupId/edit': 'edit'
      '/admin/groups/:groupId/delete': 'deleteGroup'
      '/admin/groups/:groupId/add/:identityId': 'addIdentity'
      '/admin/groups/:groupId/remove/:identityId': 'removeIdentity'

  handlers:
    list: list
    create: create
    edit: edit
    deleteGroup: deleteGroup
    addIdentity: addIdentity
    removeIdentity: removeIdentity

  globals:
    public:
      nav:
        Contacts:
          Groups: nav
      editStreamConditionOptions:
        inGroup:
          description: 'is in group...'
          show_text: true
          where: 'dashboard.query.inGroup'
        notInGroup:
          description: 'not in group...'
          show_text: true
          where: 'dashboard.query.notInGroup'

  events:
    dashboard:
      query:
        inGroup:
          do: (data) ->
            # console.log 'getting group', data.parameter
            getGroup data.parameter
            .then (group) ->
              # console.log 'got group', group?.identities?.length
              if group?.identities?.length > 0
                data.query.identity =
                  '$in': group.identities
              else
                data.query.nope = 'show no results?'
              data
        notInGroup:
          do: (data) ->
            getGroup data.parameter
            .then (group) ->
              return data if group?.identities?.length > 0
              data.query.identity =
                '$nin': group.identities
              data

  init: (next) ->
    Group
    .find (err, groups) ->
      for group in groups
        nav[group.name] = "/admin/groups/#{group._id}/edit"
      next()
