picker = angular.module('daterangepicker', [])

picker.constant('dateRangePickerConfig',
  separator: ' - '
  format: 'YYYY-MM-DD'
  clearLabel: 'Clear'
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
    opts = angular.extend({}, dateRangePickerConfig, customOpts)
    _picker = null

    clear = ->
      _picker.setStartDate()
      _picker.setEndDate()
      el.val('')

    _setStartDate = (newValue) ->
      $timeout ->
        if (_picker)
          if not newValue
            clear()
          else
            m = moment(newValue)
            if (_picker.endDate < m)
              _picker.setEndDate(m)
            _picker.setStartDate(m)

    _setEndDate = (newValue) ->
      $timeout ->
        if (_picker)
          if not newValue
            clear()
          else
            m = moment(newValue)
            if (_picker.startDate > m)
              _picker.setStartDate(m)
            _picker.setEndDate(m)

    #Watchers enable resetting of start and end dates
    $scope.$watch 'model.startDate', (newValue) ->
      _setStartDate(newValue)

    $scope.$watch 'model.endDate', (newValue) ->
      _setEndDate(newValue)

    _formatted = (viewVal) ->
      f = (date) ->
        if not moment.isMoment(date)
          return moment(date).format(opts.format)
        return date.format(opts.format)

      if opts.singleDatePicker
        f(viewVal.startDate)
      else
        [f(viewVal.startDate), f(viewVal.endDate)].join(opts.separator)

    _validateMin = (min, start) ->
      min = moment(min)
      start = moment(start)
      valid = min.isBefore(start) or min.isSame(start, 'day')
      modelCtrl.$setValidity('min', valid)
      return valid

    _validateMax = (max, end) ->
      max = moment(max)
      end = moment(end)
      valid = max.isAfter(end) or max.isSame(end, 'day')
      modelCtrl.$setValidity('max', valid)
      return valid

    modelCtrl.$formatters.push (val) ->
      if val and val.startDate and val.endDate
        # Update datepicker dates according to val before rendering.
        _setStartDate(val.startDate)
        _setEndDate(val.endDate)
        return val
      return ''

    modelCtrl.$parsers.push (val) ->
      # Check if input is valid.
      if not angular.isObject(val) or not (val.hasOwnProperty('startDate') and val.hasOwnProperty('endDate'))
        return modelCtrl.$modelValue

      # If min-max set, validate as well.
      if $scope.dateMin and val.startDate
        _validateMin($scope.dateMin, val.startDate)
      else
        modelCtrl.$setValidity('min', true)

      if $scope.dateMax and val.endDate
        _validateMax($scope.dateMax, val.endDate)
      else
        modelCtrl.$setValidity('max', true)

      return val

    modelCtrl.$isEmpty = (val) ->
      # modelCtrl is empty if val is invalid or any of the ranges are not set.
      not val or val.startDate == null or val.endDate == null

    modelCtrl.$render = ->
      if not modelCtrl.$modelValue
        return el.val('')

      if modelCtrl.$modelValue.startDate == null
        return el.val('')

      return el.val(_formatted(modelCtrl.$modelValue))

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
        el.on eventType, callbackFunction

      if attrs.clearable
        locale = opts.locale || {}
        locale.cancelLabel = opts.clearLabel
        opts.locale = locale

        el.on 'cancel.daterangepicker', () ->
          modelCtrl.$setViewValue({startDate: null, endDate: null})
          modelCtrl.$render()
          return el.trigger 'change'

      return

    _init()

    # If input is cleared manually, set dates to null.
    el.change ->
      if $.trim(el.val()) == ''
        $timeout ()->
          modelCtrl.$setViewValue(
            startDate: null
            endDate: null
          )

    if attrs.min
      $scope.$watch 'dateMin', (date) ->
        if date
          if not modelCtrl.$isEmpty(modelCtrl.$modelValue)
            _validateMin(date, modelCtrl.$modelValue.startDate)

          opts['minDate'] = moment(date)
        else
          opts['minDate'] = false
        _init()

    if attrs.max
      $scope.$watch 'dateMax', (date) ->
        if date
          if not modelCtrl.$isEmpty(modelCtrl.$modelValue)
            _validateMax(date, modelCtrl.$modelValue.endDate)

          opts['maxDate'] = moment(date)
        else
          opts['maxDate'] = false
        _init()

    if attrs.options
      $scope.$watch 'opts', (newOpts) ->
        opts = angular.extend(opts, newOpts)
        _init()

    $scope.$on '$destroy', ->
      _picker?.remove()
