picker = angular.module('daterangepicker', [])

picker.constant('dateRangePickerConfig',
  locale:
    separator: ' - '
    format: 'YYYY-MM-DD'
)

picker.directive 'dateRangePicker', ($compile, $timeout, $parse, dateRangePickerConfig) ->
  require: 'ngModel'
  restrict: 'A'
  scope:
    dateMin: '=min'
    dateMax: '=max'
    model: '=ngModel'
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
      el.val('')

    _setDatePoint = (setter) ->
      (newValue) ->
        $timeout ->
          if (_picker)
            if not newValue
              clear()
            else
              m = moment(newValue)
              setter(m)

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
        f(viewVal.startDate)
      else
        [f(viewVal.startDate), f(viewVal.endDate)].join(opts.locale.separator)

    _parse = (value) ->
      f = (val) ->
        moment(val, opts.locale.format)
      if opts.singleDatePicker
      then f(value)
      else value.split(opts.locale.separator).map(f)

    _validate = (field, validator) ->
      (expected, actual) ->
        if expected and actual
          expected = moment(expected)
          actual = moment(actual)
          valid = validator(expected, actual)
          modelCtrl.$setValidity(field, valid)
          valid
        else
          modelCtrl.$setValidity(field, true)
          true

    _validateMin = _validate 'min', (min, start) -> min.isBefore(start) or min.isSame(start, 'day')
    _validateMax = _validate 'max', (max, end) -> max.isAfter(end) or max.isSame(end, 'day')

    modelCtrl.$formatters.push (val) ->
      if val and val.startDate and val.endDate
        # Update datepicker dates according to val before rendering.
        _setStartDate(val.startDate)
        _setEndDate(val.endDate)
        return val
      ''

    modelCtrl.$parsers.push (val) ->
      # Check if input is valid.
      value = {}
      if angular.isObject(val) and val.hasOwnProperty('startDate') and val.hasOwnProperty('endDate')
        value = val
      if angular.isString(val) and val.length > 0
        x = _parse(val)
        value.startDate = x[0]
        value.endDate = x[1]

      if value.startDate or value.endDate
        _validateMin($scope.dateMin, value.startDate)
        _validateMax($scope.dateMax, value.endDate)
        return value

      modelCtrl.$modelValue

    modelCtrl.$isEmpty = (val) ->
      # modelCtrl is empty if val is invalid or any of the ranges are not set.
      not val or val.startDate == null or val.endDate == null

    modelCtrl.$render = ->
      if not modelCtrl.$modelValue or modelCtrl.$modelValue.startDate == null
      then el.val('')
      else el.val(_format(modelCtrl.$modelValue))

    _init = ->
      el.daterangepicker opts, (start, end) ->
        $timeout ->
          modelCtrl.$setViewValue({startDate: start, endDate: end})
        modelCtrl.$render()


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

    # If input is cleared manually, set dates to null.
    el.change ->
      if $.trim(el.val()) == ''
        $timeout ()->
          modelCtrl.$setViewValue(
            startDate: null
            endDate: null
          )

    _initDateField = (field, attribute, validator, modelName, optName) ->
      if attrs[attribute]
        $scope.$watch field, (date) ->
          if date
            if not modelCtrl.$isEmpty(modelCtrl.$modelValue)
              validator(date, modelCtrl.$modelValue[modelName])
            opts[optName] = moment(date)
          else
            opts[optName] = false
          _init()

    _initDateField('dateMin', 'min', _validateMin, 'startDate', 'minDate')
    _initDateField('dateMax', 'max', _validateMax, 'endDate', 'maxDate')

    if attrs.options
      $scope.$watch 'opts', (newOpts) ->
        opts = angular.merge(opts, newOpts)
        _init()
      , true

    $scope.$on '$destroy', ->
      _picker?.remove()
