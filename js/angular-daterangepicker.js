(function() {
  var picker;

  picker = angular.module('daterangepicker', []);

  picker.constant('dateRangePickerConfig', {
    cancelOnOutsideClick: true,
    locale: {
      separator: ' - ',
      format: 'YYYY-MM-DD',
      clearLabel: 'Clear'
    }
  });

  picker.directive('dateRangePicker', ['$compile', '$timeout', '$parse', 'dateRangePickerConfig', function($compile, $timeout, $parse, dateRangePickerConfig) {
    return {
      require: 'ngModel',
      restrict: 'A',
      scope: {
        min: '=',
        max: '=',
        picker: '=?',
        model: '=ngModel',
        opts: '=options',
        clearable: '='
      },
      link: function($scope, element, attrs, modelCtrl) {
        var _clear, _init, _initBoundaryField, _mergeOpts, _picker, _setDatePoint, _setEndDate, _setStartDate, _validate, _validateMax, _validateMin, customOpts, el, getViewValue, opts;
        _mergeOpts = function() {
          var extend, localeExtend;
          localeExtend = angular.extend.apply(angular, Array.prototype.slice.call(arguments).map(function(opt) {
            return opt != null ? opt.locale : void 0;
          }).filter(function(opt) {
            return !!opt;
          }));
          extend = angular.extend.apply(angular, arguments);
          extend.locale = localeExtend;
          return extend;
        };
        el = $(element);
        el.attr('ng-trim', 'false');
        attrs.ngTrim = 'false';
        customOpts = $scope.opts;
        opts = _mergeOpts({}, angular.copy(dateRangePickerConfig), customOpts);
        _picker = null;
        _clear = function() {
          _picker.setStartDate();
          return _picker.setEndDate();
        };
        _setDatePoint = function(setter) {
          return function(newValue) {
            if (newValue && (!moment.isMoment(newValue) || newValue.isValid())) {
              newValue = moment(newValue);
            } else {
              return;
            }
            if (_picker) {
              return setter(newValue);
            }
          };
        };
        _setStartDate = _setDatePoint(function(date) {
          if (date && _picker.endDate < date) {
            _picker.setEndDate(date);
          }
          opts.startDate = date;
          return _picker.setStartDate(date);
        });
        _setEndDate = _setDatePoint(function(date) {
          if (date && _picker.startDate > date) {
            _picker.setStartDate(date);
          }
          opts.endDate = date;
          return _picker.setEndDate(date);
        });
        _validate = function(validator) {
          return function(boundary, actual) {
            if (boundary && actual) {
              return validator(moment(boundary), moment(actual));
            } else {
              return true;
            }
          };
        };
        _validateMin = _validate(function(min, start) {
          return min.isBefore(start) || min.isSame(start, 'day');
        });
        _validateMax = _validate(function(max, end) {
          return max.isAfter(end) || max.isSame(end, 'day');
        });
        getViewValue = function(model) {
          var f, viewValue;
          f = function(date) {
            if (!moment.isMoment(date)) {
              return moment(date).format(opts.locale.format);
            } else {
              return date.format(opts.locale.format);
            }
          };
          if (opts.singleDatePicker && model) {
            viewValue = f(model);
          } else if (model && (model.startDate || model.endDate)) {
            viewValue = [f(model.startDate), f(model.endDate)].join(opts.locale.separator);
          } else {
            viewValue = '';
          }
          return viewValue;
        };
        modelCtrl.$formatters.push(function(modelValue) {
          return getViewValue(modelValue);
        });
        modelCtrl.$renderOriginal = modelCtrl.$render;
        modelCtrl.$render = function() {
          if (modelCtrl.$modelValue && opts.singleDatePicker) {
            _setStartDate(modelCtrl.$modelValue);
            _setEndDate(modelCtrl.$modelValue);
          }
          if (modelCtrl.$modelValue && (modelCtrl.$modelValue.startDate || modelCtrl.$modelValue.endDate)) {
            _setStartDate(modelCtrl.$modelValue.startDate);
            _setEndDate(modelCtrl.$modelValue.endDate);
          } else {
            _clear();
          }
          return modelCtrl.$renderOriginal();
        };
        modelCtrl.$parsers.push(function(viewValue) {
          var f, objValue, x;
          f = function(value) {
            var date;
            date = moment(value, opts.locale.format);
            return (date.isValid() && date) || null;
          };
          objValue = opts.singleDatePicker ? null : {
            startDate: null,
            endDate: null
          };
          if (angular.isString(viewValue) && viewValue.length > 0) {
            if (opts.singleDatePicker) {
              objValue = f(viewValue);
            } else {
              x = viewValue.split(opts.locale.separator).map(f);
              objValue.startDate = x[0] ? x[0].startOf('day') : null;
              objValue.endDate = x[1] ? x[1].endOf('day') : null;
            }
          }
          return objValue;
        });
        modelCtrl.$isEmpty = function(val) {
          return !(angular.isString(val) && val.length > 0);
        };
        _init = function() {
          var eventType, results;
          el.daterangepicker(angular.extend(opts, {
            autoUpdateInput: false
          }), function(startDate, endDate, label) {
            return $scope.$apply(function() {
              if (typeof opts.changeCallback === "function") {
                return opts.changeCallback.apply(this, arguments);
              }
            });
          });
          _picker = el.data('daterangepicker');
          $scope.picker = _picker;
          _picker.container.hide();
          _picker.container.addClass((opts.pickerClasses || "") + " " + (attrs['pickerClasses'] || ""));
          el.on('show.daterangepicker', function(ev, picker) {
            return $scope.$apply(function() {
              if (opts.singleDatePicker) {
                if (!picker.startDate.isSame($scope.model)) {
                  _setStartDate($scope.model);
                  _setEndDate($scope.model);
                }
              } else {
                if (!picker.startDate.isSame($scope.model.startDate)) {
                  _setStartDate($scope.model.startDate);
                }
                if (!picker.endDate.isSame($scope.model.endDate)) {
                  _setEndDate($scope.model.endDate);
                }
              }
              picker.updateView();
            });
          });
          el.on('apply.daterangepicker', function(ev, picker) {
            return $scope.$apply(function() {
              if (opts.singleDatePicker) {
                if (!picker.startDate) {
                  $scope.model = null;
                } else if (!picker.startDate.isSame($scope.model)) {
                  $scope.model = picker.startDate;
                }
              } else if (!picker.startDate.isSame(picker.oldStartDate) || !picker.endDate.isSame(picker.oldEndDate) || !picker.startDate.isSame($scope.model.startDate) || !picker.endDate.isSame($scope.model.endDate)) {
                $scope.model = {
                  startDate: picker.startDate,
                  endDate: picker.endDate,
                  label: picker.chosenLabel
                };
              }
            });
          });
          el.on('outsideClick.daterangepicker', function(ev, picker) {
            if (opts.cancelOnOutsideClick) {
              return $scope.$apply(function() {
                return picker.clickCancel();
              });
            } else {
              return picker.clickApply();
            }
          });
          results = [];
          for (eventType in opts.eventHandlers) {
            results.push(el.on(eventType, function(ev, picker) {
              var eventName;
              eventName = ev.type + '.' + ev.namespace;
              return $scope.$evalAsync(opts.eventHandlers[eventName]);
            }));
          }
          return results;
        };
        _init();
        $scope.$watch((function() {
          return getViewValue($scope.model);
        }), function(viewValue) {
          if (typeof modelCtrl.$processModelValue === "function") {
            return modelCtrl.$processModelValue();
          } else {
            if (typeof modelCtrl.$$updateEmptyClasses === "function") {
              modelCtrl.$$updateEmptyClasses(viewValue);
            }
            modelCtrl.$viewValue = modelCtrl.$$lastCommittedViewValue = viewValue;
            return modelCtrl.$render();
          }
        });
        _initBoundaryField = function(field, validator, modelField, optName) {
          if (attrs[field]) {
            modelCtrl.$validators[field] = function(value) {
              return value && validator(opts[optName], value[modelField]);
            };
            return $scope.$watch(field, function(date) {
              opts[optName] = date ? moment(date) : false;
              return _init();
            });
          }
        };
        _initBoundaryField('min', _validateMin, 'startDate', 'minDate');
        _initBoundaryField('max', _validateMax, 'endDate', 'maxDate');
        if (attrs.options) {
          $scope.$watch('opts', function(newOpts) {
            opts = _mergeOpts(opts, newOpts);
            return _init();
          }, true);
        }
        if (attrs.clearable) {
          $scope.$watch('clearable', function(newClearable) {
            if (newClearable) {
              opts = _mergeOpts(opts, {
                locale: {
                  cancelLabel: opts.locale.clearLabel
                }
              });
            }
            _init();
            if (newClearable) {
              return el.on('cancel.daterangepicker', function() {
                return $scope.$apply(function() {
                  return $scope.model = opts.singleDatePicker ? null : {
                    startDate: null,
                    endDate: null
                  };
                });
              });
            }
          });
        }
        return $scope.$on('$destroy', function() {
          return _picker != null ? _picker.remove() : void 0;
        });
      }
    };
  }]);

}).call(this);
