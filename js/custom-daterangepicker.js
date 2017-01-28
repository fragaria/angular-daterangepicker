/**
 * Custom Date Range Picker Directive.
 *
 *   <custom-date-range-picker ng-model="timeperiod"/>
 *
 *   timeperiod = {
 *     defaultLabel:'Anytime',
 *     chosenLabel:'Last 1 Hour',
 *     start:moment().utc(),
 *     end:moment().utc(),
 *     number:1,
 *     period:'hours'
 *   }
 */
(function () {
    'use strict';
    var custom;

    custom = angular.module('customdaterangepicker', []);

    custom.directive('customDateRangePicker', ['$timeout', customDateRangePickerDirective]);

    function customDateRangePickerDirective ($timeout) {

        return {
            restrict: 'E',
            scope: {
                ngModel: "=",
                options: '=?'    // options (optional)
            },
            template: '<input date-range-picker type="text" class="form-control date-picker custom-date-picker" ng-model="daterange" options="options" />',
            controller: function($scope){

                // Overwrite input value with date range label i.e. "Last 30 Days"
                $scope.setLabel = function(label, elem) {
                    if(label) {
                        $timeout( function () {
                            elem.find('.date-picker').val(label);
                            $scope.$apply();
                        }, 0);
                    }
                };

                // Set the time period i.e. number:1, period:'days'
                $scope.setTimeperiod = function(label, elem) {
                    var timeperiod = $scope.getDaterangeByLabel(label);

                    $scope.ngModel.chosenLabel = label;
                    $scope.ngModel.start = null;    // custom range
                    $scope.ngModel.end   = null;    // custom range
                    $scope.ngModel.number = timeperiod.number;
                    $scope.ngModel.period = timeperiod.period;

                    $scope.setLabel(label, elem);
                };

                // Return daterange for label in options.ranges
                $scope.getDaterangeByLabel = function(label) {
                    var daterange = {};
                    angular.forEach($scope.options.ranges, function(range, key) {
                        if(label === key) {
                            daterange = { startDate:range[0], endDate:range[1], number:range[2], period:range[3] };
                        }
                    });
                    return daterange;
                };
            },
            link: function (scope, elem, attr) {

                // merge date-range-picker options
                scope.options = angular.extend({}, {
                    timePicker: true,           // Allow selection of dates with times, not just dates
                    timePicker24Hour: true,     // Use 24-hour instead of 12-hour times, removing the AM/PM selection
                    autoApply: true,            // Hide the apply and cancel buttons
                    linkedCalendars: false,     // The two calendars can be individually advanced and display any month/year.
                    maxDate: moment().utc(),          // The latest date a user may select
                    showDropdowns: true,        // Show year and month select boxes above calendars to jump to a specific month and year
                    showCustomRangeLabel: true,
                    applyClass: 'btn-info',
                    locale: {
                        fromLabel: "From",
                        format: "DD-MMM-YYYY",
                        toLabel: "To",
                        customRangeLabel: 'Custom'
                    },

                    ranges: {
                        'Last 7 Days': [moment().utc().subtract(7, 'days'), moment().utc(), 7, 'days'],
                        'Last 30 Days': [moment().utc().subtract(30, 'days'), moment().utc(), 30, 'days'],
                        'Last 90 Days': [moment().utc().subtract(90, 'days'), moment().utc(), 90, 'days']
                    },

                    callback: function(start, end, chosenLabel) {
                        var customRangeLabel = scope.options.locale.customRangeLabel;
                        if(chosenLabel == customRangeLabel) {
                            // Update custom range start and end dates
                            scope.ngModel.start = start;
                            scope.ngModel.end = end;
                            scope.ngModel.number = null;
                            scope.ngModel.period = null;

                            start = start.format('DD-MMM-YYYY HH:mm');
                            end = end.format('DD-MMM-YYYY HH:mm');
                            var label = start + ' - ' + end;
                            scope.setLabel(label, elem);
                        } else {
                            // Update datepicker label
                            scope.setTimeperiod(chosenLabel, elem);
                        }

                    }
                }, scope.options);

                // Get the daterange by label
                scope.daterange = scope.getDaterangeByLabel(scope.ngModel.defaultLabel);

                // Initialize daterangepicker label
                scope.setTimeperiod(scope.ngModel.defaultLabel, elem);

                // Update the daterangepicker label
                scope.$watch('ngModel.chosenLabel', function (newValue, oldValue) {
                    if (scope.ngModel.chosenLabel !== undefined) {
                        scope.setTimeperiod(newValue, elem);
                   }
               });
            },
        }
    }
})()
