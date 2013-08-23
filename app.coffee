url = "https://opentracker.firebaseio.com"
app = angular.module("opentrackerapp", ["firebase"])
app.controller "AppCtrl", ["$scope", "angularFire", "angularFireAuth", AppCtrl = (scope, angularFire, angularFireAuth) ->
  generateProjectId = ->
    id = (if scope.user.projects then scope.user.projects.length + 1 else 1)
    "p" + scope.auth_user.id + "_" + id

  safeApply = (fn) ->
    window.setTimeout ->
      (if (scope.$$phase or scope.$root.$$phase) then fn() else scope.$apply(fn))

  associateProject = (project_id) ->
    angularFire(url + "/projects/" + project_id, scope, project_id, {}).then (result) ->

  window.scope = scope
  scope.signin = (id) ->
    angularFireAuth.login id

  scope.signout = (id) ->
    angularFireAuth.logout()

  scope.add = (project) ->
    if project.id #edit project
      p = scope[project.id]
      p.name = scope.project.name
      p.desc = scope.project.desc
      scope.project = {}
    else #create new project
      project_id = generateProjectId()

      scope.project.creator_id = scope.auth_user.id
      scope.project.id         = project_id

      new Firebase(url + "/projects/" + project_id).set scope.project, (error) ->
        console.log "message from server:", error
        safeApply ->
          if scope.user.projects
            scope.user.projects.push project_id
          else
            scope.user.projects = [project_id]
          scope.project = {}
          associateProject project_id

  scope.editProject = (project_id) ->
    scope.project = angular.copy(scope[project_id])

  scope.escape = (str) ->
    str.replace /\./g, "_"

  scope.project = {}
  angularFireAuth.initialize url,
    name: "auth_user"

  scope.$watch "auth_user", ->
    if scope.auth_user
      path = url + "/users/" + scope.auth_user.id
      angularFire(path, scope, "user", {}).then (result) ->
        scope.disassociate_user = result
        if Object.keys(scope.user).length is 0
          safeApply ->
            scope.user.email       = scope.auth_user.email
            scope.user.displayName = scope.auth_user.displayName or scope.auth_user.username
            scope.user.name        = scope.auth_user.name or scope.auth_user.username

        if scope.user.projects
          scope.user.projects.forEach (project_id) ->
            associateProject project_id


    else
      scope.disassociate_user()  if scope.disassociate_user
      scope.user = null

]

angular.bootstrap document, ['opentrackerapp']
