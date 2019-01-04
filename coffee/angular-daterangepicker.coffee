pickerModule = angular.module('daterangepicker', [])

pickerModule.constant('dateRangePickerConfig',
  cancelOnOutsideClick: true
  locale:
    separator: ' - '
    format: 'YYYY-MM-DD'
    clearLabel: 'Clear'
)

pickerModule.directive 'dateRangePicker', ($compile, $timeout, $parse, dateRangePickerConfig) ->
  require: 'ngModel'
  restrict: 'A'
  scope:
    min: '='
    max: '='
    picker: '=?'
    model: '=ngModel'
    opts: '=options'
    clearable: '='
  link: ($scope, element, attrs, modelCtrl) ->
    # Custom angular extend function to extend locales, so they are merged instead of overwritten
    # angular.merge removes prototypes...
    _mergeOpts = () ->
      localeExtend = angular.extend.apply(angular,
        Array.prototype.slice.call(arguments).map((opt) -> opt?.locale).filter((opt) -> !!opt))
      extend = angular.extend.apply(angular, arguments)
      extend.locale = localeExtend
      extend

    el = $(element)
    # can interfere with local.separator & $parsers if startDate is empty
    el.attr('ng-trim','false')
    attrs.ngTrim = 'false'

    allowInvalid = false
    do setModelOptions = ->
      # must only update on change, otherwise in the middle of typing it will update the $viewValue
      if (modelCtrl.$options && typeof modelCtrl.$options.getOption == 'function')
        updateOn = modelCtrl.$options.getOption('updateOn')
        allowInvalid = !!modelCtrl.$options.getOption('allowInvalid')
      else # angular < 1.6
        updateOn = (modelCtrl.$options && modelCtrl.$options.updateOn) || ""
        allowInvalid = !!(modelCtrl.$options && modelCtrl.$options.allowInvalid)

      if (!updateOn.includes("change"))
        if (typeof modelCtrl.$overrideModelOptions == 'function')
          updateOn += " change"
          modelCtrl.$overrideModelOptions({'*':'$inherit', updateOn})
        else
          # angular < 1.6
          updateOn += " change"
          updateOn.replace(/default/g,' ')
          options = angular.copy(modelCtrl.$options) || {}
          options.updateOn = updateOn
          options.updateOnDefault = false
          modelCtrl.$options = options

    customOpts = $scope.opts
    opts = _mergeOpts({}, angular.copy(dateRangePickerConfig), customOpts)
    _picker = null

    _clear = ->
      # if no initial value given this will be called in $render before picker
      if (_picker)
        _picker.setStartDate()
        _picker.setEndDate()

    _setDatePoint = (setter) ->
      (newValue) ->
        if (newValue && (!moment.isMoment(newValue) || newValue.isValid()))
          newValue = moment(newValue)
        else
          # keep previous value if invalid
          # set newValue = {} to default it
          return

        if _picker
          setter(newValue)

    _setStartDate = _setDatePoint (date) ->
      if (date && _picker.endDate < date)
        # end's before start, so push end date out to start date
        _picker.setEndDate(date)
      _picker.setStartDate(date)
      opts.startDate = _picker.startDate #picker would have adjusted it to match max/mins

    _setEndDate = _setDatePoint (date) ->
      # this just flips start and end if they are reverse chronological
      if (date && _picker.startDate > date)
        # daterangepicker will set the end date to a clone of the start date if it's before start
        # so end will become what the start date is currently anyway
        _picker.setEndDate(_picker.startDate)
        opts.endDate = _picker.endDate #will be previous start date

        # the new start date is actually this lesser date
        _picker.setStartDate(date)
        opts.startDate = _picker.startDate #picker would have adjusted it to match max/mins
      else
        _picker.setEndDate(date)
        opts.endDate = _picker.endDate

    getViewValue =(model) ->
      f = (date) ->
        if not moment.isMoment(date)
        then moment(date).format(opts.locale.format)
        else date.format(opts.locale.format)

      if opts.singleDatePicker and model
        viewValue = f(model)
      else if model and (model.startDate || model.endDate)
        viewValue = [f(model.startDate), f(model.endDate)].join(opts.locale.separator)
      else
        viewValue = ''
      return viewValue

    # Formatter should return just the string value of the input
    # It is used for comparison of if we should re-render
    modelCtrl.$formatters.push (modelValue) ->
      getViewValue(modelValue)

    # Render should update the date picker start/end dates as necessary
    # It should also set the input element's val with $viewValue as we don't let the rangepicker do this
    modelCtrl.$renderOriginal = modelCtrl.$render
    modelCtrl.$render = () ->
      # Update the calendars
      if modelCtrl.$modelValue and opts.singleDatePicker
        _setStartDate(modelCtrl.$modelValue)
        _setEndDate(modelCtrl.$modelValue)
      else if modelCtrl.$modelValue and (modelCtrl.$modelValue.startDate || modelCtrl.$modelValue.endDate)
        _setStartDate(modelCtrl.$modelValue.startDate)
        _setEndDate(modelCtrl.$modelValue.endDate)
      else _clear()

      if (modelCtrl.$valid)
        # Update the input with the $viewValue (generated from $formatters)
        modelCtrl.$renderOriginal()

    # This should parse the string input into an updated model object
    modelCtrl.$parsers.push (viewValue) ->
      # Parse the string value
      f = (value) ->
        date = moment(value, opts.locale.format)
        return (date.isValid() && date) || null

      objValue = if opts.singleDatePicker then null else
        startDate: null
        endDate: null

      if angular.isString(viewValue) and viewValue.length > 0
        if opts.singleDatePicker
          objValue = f(viewValue)
        else
          x = viewValue.split(opts.locale.separator).map(f)
          # Use startOf/endOf day to comply with how daterangepicker works
          objValue.startDate = if x[0] then x[0].startOf('day') else null
          # selected value will always be 999ms off due to:
          # https://github.com/dangrossman/daterangepicker/issues/1890
          # can fix by adding .startOf('second') but then initial value will be off by 999ms
          objValue.endDate = if x[1] then x[1].endOf('day') else null
      return objValue

    modelCtrl.$isEmpty = (val) ->
      # modelCtrl is empty if val is empty string
      not (angular.isString(val) and val.length > 0)

    # _init has to be called anytime we make changes to the date picker options
    _init = ->
      # disable autoUpdateInput, can't handle empty values without it.  Our callback here will
      # update our $viewValue, which triggers the $parsers
      el.daterangepicker angular.extend(opts, {autoUpdateInput: false}), (startDate, endDate, label) ->
        $scope.$apply () ->
          # this callback is triggered any time the calendar is changed, even if it wasn't applied
          # so a range is changed, but not applied and then clicked out of, this triggers when outsideClick calls hide
          # therefore can't assign to model here
          # https://github.com/dangrossman/daterangepicker/issues/1156
          # $scope.model = if opts.singleDatePicker then startDate else {startDate, endDate, label}
          if (typeof opts.changeCallback == "function")
            opts.changeCallback.apply(this, arguments)

      # Needs to be after daterangerpicker has been created, otherwise
      # watchers that reinit will be attached to old daterangepicker instance.
      _picker = el.data('daterangepicker')
      $scope.picker = _picker
      # to set initial dropdown to inline hide for when default display isn't hidden (eg display: flex/grid)
      _picker.container.hide()
      _picker.container.addClass((opts.pickerClasses || "") + " " + (attrs['pickerClasses'] || ""))

      el.on 'show.daterangepicker', (ev, picker) ->
        el.addClass('picker-open')

        # there are some cases where daterangepicker is buggy and the date won't match
        # make sure it does here
        # (if doing it here, does it really need to be set in the $render? probably for consistency)
        $scope.$apply ->
          if (opts.singleDatePicker)
            if (!picker.startDate.isSame($scope.model))
              _setStartDate($scope.model)
              _setEndDate($scope.model)
          else
            if ($scope.model && !picker.startDate.isSame($scope.model.startDate))
              _setStartDate($scope.model.startDate)
            if ($scope.model && !picker.endDate.isSame($scope.model.endDate))
              _setEndDate($scope.model.endDate)
          picker.updateView()
          return

      el.on 'hide.daterangepicker', (ev, picker) ->
        el.removeClass('picker-open')

      el.on 'apply.daterangepicker', (ev, picker) ->
        $scope.$apply ->
          if opts.singleDatePicker
            if !picker.startDate
              $scope.model = null
            else if !picker.startDate.isSame($scope.model)
              $scope.model = picker.startDate
          else if ( !picker.startDate.isSame(picker.oldStartDate) || !picker.endDate.isSame(picker.oldEndDate) ||
                   !$scope.model ||
                   !picker.startDate.isSame($scope.model.startDate) || !picker.endDate.isSame($scope.model.endDate)
                   )
            $scope.model = {
              startDate: picker.startDate
              endDate: picker.endDate
              label: picker.chosenLabel
            }
          return

      el.on 'outsideClick.daterangepicker', (ev, picker) ->
        if opts.cancelOnOutsideClick
          $scope.$apply ->
            # need to prevent clearing if option is on
            picker.cancelingClick = true
            picker.clickCancel()
        else
          picker.clickApply()

      # Ability to attach event handlers. See https://github.com/fragaria/angular-daterangepicker/pull/62
      # Revised
      for eventType of opts.eventHandlers
        el.on eventType, (ev, picker) ->
          eventName = ev.type + '.' + ev.namespace
          $scope.$evalAsync(opts.eventHandlers[eventName])

      # if model was already created and validation case changed this will catch that
      # and update the model if it was null from previous but no longer invalid
      modelCtrl.$validate()
      if (!$scope.model)
        el.trigger('change')

    # init will be called by opt watcher
    # _init()

    # Since model is an object whose parameters might not change while the value does,
    # need to handle what ngModelWatch doesn't
    $scope.$watch (-> getViewValue($scope.model)) , (viewValue) ->
    #  if (modelCtrl.$invalid)
    #    modelCtrl.$viewValue = null
      if (typeof modelCtrl.$processModelValue == "function")
        modelCtrl.$processModelValue()
        # will skip render if view wasn't updated, but view is skipped
        # the first time after a validation error since it's still $invalid
        # so need to make sure it's run again just in case
        modelCtrl.$render()
      else
        # maintain angular compatibility with < 1.7
        if (typeof modelCtrl.$$updateEmptyClasses == "function")
          modelCtrl.$$updateEmptyClasses(viewValue)
        # maintain angular compatibility with < 1.6
        modelCtrl.$viewValue = modelCtrl.$$lastCommittedViewValue = viewValue
        modelCtrl.$render()


    modelCtrl.$validators['invalid'] =(value, viewValue) ->
      applicable = attrs.required && !modelCtrl.$isEmpty(viewValue)
      if opts.singleDatePicker
        check = value && value.isValid()
      else
        check = value && value.startDate && value.startDate.isValid() && value.endDate && value.endDate.isValid()
      return !applicable || !!check

    # Validation for our min/max
    _validateRange = (date, min, max) ->
      if date and (min or max)
        [date, min, max] = [date, min, max].map (d) ->
          if (d)
            moment(d)
          else d
        return (!min or min.isBefore(date) or min.isSame(date, 'day')) and
               (!max or max.isSame(date, 'day') or max.isAfter(date))
      else true

    # Add validation/watchers for our min/max fields
    _initBoundaryField = (field, validator, modelField, optName) ->
      modelCtrl.$validators[field] = (value) ->
        # always have validator so if min/max change, this works
        # just return true if not set
        if (!opts[optName])
          return true

        if (opts.singleDatePicker)
          if field == 'min'
            !value || validator(value, opts['minDate'], value)
          else if field == 'max'
            !value || validator(value, value, opts['maxDate'])
        else
          value and validator(value[modelField], opts['minDate'], opts['maxDate'])

      if attrs[field]
        $scope.$watch field, (date) ->
          opts[optName] = if date then moment(date) else false
          if (_picker)
            _picker[optName] = opts[optName]
            $timeout -> modelCtrl.$validate()


    _initBoundaryField('min', _validateRange, 'startDate', 'minDate')
    _initBoundaryField('max', _validateRange, 'endDate', 'maxDate')

    # Watch our options
    $scope.$watch 'opts', (newOpts = {}) ->
      opts = _mergeOpts(opts, newOpts)
      _init()
    , true

    # Watch clearable flag
    if attrs.clearable
      $scope.$watch 'clearable', (newClearable) ->
        if newClearable
          opts = _mergeOpts(opts, {locale: {cancelLabel: opts.locale.clearLabel}})
        _init()
        if newClearable
          el.on 'cancel.daterangepicker', (ev, picker) ->
            if (!picker.cancelingClick)
              $scope.model = if opts.singleDatePicker then null else {startDate: null, endDate: null}
              el.val("")
            picker.cancelingClick = null
            $timeout -> $scope.$apply()

    $scope.$on '$destroy', ->
      _picker?.remove()
