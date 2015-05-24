picker = angular.module('daterangepicker', [])

picker.value('dateRangePickerConfig',
    separator: ' - '
    format: 'YYYY-MM-DD'
)

picker.directive('dateRangePicker', ($compile, $timeout, $parse, dateRangePickerConfig) ->
    require: 'ngModel'
    restrict: 'A'
    scope:
        dateMin: '=min'
        dateMax: '=max'
        opts: '=options'
    link: ($scope, element, attrs, modelCtrl) ->
        el = $(element)
        customOpts = $parse(attrs.dateRangePicker)($scope, {})
        opts = angular.extend({}, dateRangePickerConfig, customOpts)
        _picker = null

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

        modelCtrl.$formatters.push((val) ->
            if val and val.startDate and val.endDate
                # Update datepicker dates according to val before rendering.
                _picker.setStartDate(val.startDate)
                _picker.setEndDate(val.endDate)
                return val
            return ''
        )

        modelCtrl.$parsers.push((val) ->
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
        )

        modelCtrl.$isEmpty = (val) ->
            # modelCtrl is empty if val is invalid or any of the ranges are not set.
            not val or (val.startDate == null or val.endDate == null)

        modelCtrl.$render = ->
            if not modelCtrl.$modelValue
                return el.val('')

            if modelCtrl.$modelValue.startDate == null
                return el.val('')

            return el.val(_formatted(modelCtrl.$modelValue))


        _init = ->
            el.daterangepicker(opts, (start, end, label) ->
                $timeout(->
                  $scope.$apply(->
                      modelCtrl.$setViewValue({
                          startDate: start.toDate()
                          endDate: end.toDate()
                          label: label
                      })
                      modelCtrl.$render()
                  ))
            )
            _picker = el.data('daterangepicker')
            el

        _init()

        # If input is cleared manually, set dates to null.
        el.change(() ->
            if $.trim(el.val()) == ''
                $timeout(->
                    $scope.$apply(->
                        modelCtrl.$setViewValue(
                            startDate: null
                            endDate: null
                        )
                    ))
        )

        if attrs.min
            $scope.$watch('dateMin', (date) ->
                if date
                    if not modelCtrl.$isEmpty(modelCtrl.$modelValue)
                        _validateMin(date, modelCtrl.$modelValue.startDate)

                    opts['minDate'] = moment(date)
                else
                    opts['minDate'] = false
                _init()
            )

        if attrs.max
            $scope.$watch('dateMax', (date) ->
                if date
                    if not modelCtrl.$isEmpty(modelCtrl.$modelValue)
                        _validateMax(date, modelCtrl.$modelValue.endDate)

                    opts['maxDate'] = moment(date)
                else
                    opts['maxDate'] = false

                _init()
            )

        if attrs.options
            $scope.$watch('opts', (newOpts) ->
                opts = angular.extend(opts, newOpts)
                _init()
            )

        $scope.$on '$destroy', ->
            _picker.remove()
)
