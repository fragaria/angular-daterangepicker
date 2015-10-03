picker = angular.module('daterangepicker', [])

picker.constant('dateRangePickerConfig',
  clearLabel: 'Clear'
  locale:
    separator: ' - '
    format: 'YYYY-MM-DD'
)

picker.directive 'dateRangePicker', ($compile, $timeout, $parse, dateRangePickerConfig) ->
  require: 'ngModel'
  restrict: 'A'
  scope:
    min: '='
    max: '='
    model: '=ngmodel'
    opts: '=options'
    clearable: '='
  link: ($scope, element, attrs, modelCtrl) ->
    el = $(element)
    customOpts = $scope.opts
    opts = angular.merge({}, dateRangePickerConfig, customOpts)
    _picker = null

    clear = ->
      _picker.setStartDate()
      _picker.setEndDate()

    _setDatePoint = (setter) ->
      (newValue) ->
        if (_picker)
          if not newValue
          then clear()
          else setter(moment(newValue))

    _setStartDate = _setDatePoint (m) ->
      if (_picker.endDate < m)
        _picker.setEndDate(m)
      _picker.setStartDate(m)

    _setEndDate = _setDatePoint (m) ->
      if (_picker.startDate > m)
        _picker.setStartDate(m)
      _picker.setEndDate(m)

    #Watchers enable resetting of start and end dates
    $scope.$watch 'model.startDate', _setStartDate
    $scope.$watch 'model.endDate', _setEndDate

    _format = (viewVal) ->
      f = (date) ->
        if not moment.isMoment(date)
        then moment(date).format(opts.locale.format)
        else date.format(opts.locale.format)

      if opts.singleDatePicker
      then f(viewVal.startDate)
      else [f(viewVal.startDate), f(viewVal.endDate)].join(opts.locale.separator)

    _parse = (value) ->
      f = (val) ->
        moment(val, opts.locale.format)
      if opts.singleDatePicker
      then f(value)
      else value.split(opts.locale.separator).map(f)

    _validate = (validator) ->
      (boundary, actual) ->
        if boundary and actual
        then validator(moment(boundary), moment(actual))
        else true

    _validateMin = _validate (min, start) -> min.isBefore(start) or min.isSame(start, 'day')
    _validateMax = _validate (max, end) -> max.isAfter(end) or max.isSame(end, 'day')

    modelCtrl.$formatters.push (val) ->
      if val and val.startDate
      then _format(val)
      else ''

    modelCtrl.$parsers.push (val) ->
      # Check if input is valid.
      value =
        startDate: null
        endDate: null
      if angular.isString(val) and val.length > 0
        x = _parse(val)
        value.startDate = x[0]
        value.endDate = x[1]
      value

    modelCtrl.$isEmpty = (val) ->
      # modelCtrl is empty if val is invalid or any of the ranges are not set.
      not val or val.startDate == null or val.endDate == null

    modelCtrl.$render = ->
      if modelCtrl.$modelValue and modelCtrl.$modelValue.startDate != null
        _setStartDate(modelCtrl.$modelValue.startDate)
        _setEndDate(modelCtrl.$modelValue.endDate)
      else
        clear()

    _init = ->
      el.daterangepicker opts

      # Needs to be after daterangerpicker has been created, otherwise
      # watchers that reinit will be attached to old daterangepicker instance.
      _picker = el.data('daterangepicker')

      #Ability to attach event handlers. See https://github.com/fragaria/angular-daterangepicker/pull/62
      for eventType, callbackFunction of opts.eventHandlers
        el.on eventType, () ->
          $scope.$evalAsync(callbackFunction)

      if attrs.clearable
        locale = opts.locale || {}
        locale.cancelLabel = opts.clearLabel
        opts.locale = locale

        el.on 'cancel.daterangepicker', () ->
          modelCtrl.$setViewValue({startDate: null, endDate: null})
          modelCtrl.$render()
          return el.trigger 'change'

    _init()

    _initBoundaryField = (field, validator, modelField, optName) ->
      if attrs[field]
        modelCtrl.$validators[field] = (value) ->
          validator(opts[optName], value[modelField])
        $scope.$watch field, (date) ->
          opts[optName] = if date then moment(date) else false
          _init()

    _initBoundaryField('min', _validateMin, 'startDate', 'minDate')
    _initBoundaryField('max', _validateMax, 'endDate', 'maxDate')

    if attrs.options
      $scope.$watch 'opts', (newOpts) ->
        opts = angular.merge(opts, newOpts, {autoUpdateInput: false})
        _init()
      , true

    $scope.$on '$destroy', ->
      _picker?.remove()
