(function() {
  var pickerModule;

  pickerModule = angular.module('daterangepicker', []);

  pickerModule.constant('dateRangePickerConfig', {
    cancelOnOutsideClick: true,
    locale: {
      separator: ' - ',
      format: 'YYYY-MM-DD',
      clearLabel: 'Clear'
    }
  });

  pickerModule.directive('dateRangePicker', ['$compile', '$timeout', '$parse', 'dateRangePickerConfig', function($compile, $timeout, $parse, dateRangePickerConfig) {
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
        var _clear, _init, _initBoundaryField, _mergeOpts, _picker, _setDatePoint, _setEndDate, _setStartDate, _validateRange, allowInvalid, customOpts, el, getViewValue, opts, setModelOptions;
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
        allowInvalid = false;
        (setModelOptions = function() {
          var options, updateOn;
          if (modelCtrl.$options && typeof modelCtrl.$options.getOption === 'function') {
            updateOn = modelCtrl.$options.getOption('updateOn');
            allowInvalid = !!modelCtrl.$options.getOption('allowInvalid');
          } else {
            updateOn = (modelCtrl.$options && modelCtrl.$options.updateOn) || "";
            allowInvalid = !!(modelCtrl.$options && modelCtrl.$options.allowInvalid);
          }
          if (updateOn.indexOf("change") === -1) {
            if (typeof modelCtrl.$overrideModelOptions === 'function') {
              updateOn += " change";
              return modelCtrl.$overrideModelOptions({
                '*': '$inherit',
                updateOn: updateOn
              });
            } else {
              updateOn += " change";
              updateOn.replace(/default/g, ' ');
              options = angular.copy(modelCtrl.$options) || {};
              options.updateOn = updateOn;
              options.updateOnDefault = false;
              return modelCtrl.$options = options;
            }
          }
        })();
        customOpts = $scope.opts;
        opts = _mergeOpts({}, angular.copy(dateRangePickerConfig), customOpts);
        _picker = null;
        _clear = function() {
          if (_picker) {
            _picker.setStartDate();
            return _picker.setEndDate();
          }
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
          _picker.setStartDate(date);
          return opts.startDate = _picker.startDate;
        });
        _setEndDate = _setDatePoint(function(date) {
          if (date && _picker.startDate > date) {
            _picker.setEndDate(_picker.startDate);
            opts.endDate = _picker.endDate;
            _picker.setStartDate(date);
            return opts.startDate = _picker.startDate;
          } else {
            _picker.setEndDate(date);
            return opts.endDate = _picker.endDate;
          }
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
          } else if (modelCtrl.$modelValue && (modelCtrl.$modelValue.startDate || modelCtrl.$modelValue.endDate)) {
            _setStartDate(modelCtrl.$modelValue.startDate);
            _setEndDate(modelCtrl.$modelValue.endDate);
          } else {
            _clear();
          }
          if (modelCtrl.$valid) {
            return modelCtrl.$renderOriginal();
          }
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
          var eventType;
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
            el.addClass('picker-open');
            return $scope.$apply(function() {
              if (opts.singleDatePicker) {
                if (!picker.startDate.isSame($scope.model)) {
                  _setStartDate($scope.model);
                  _setEndDate($scope.model);
                }
              } else {
                if ($scope.model && !picker.startDate.isSame($scope.model.startDate)) {
                  _setStartDate($scope.model.startDate);
                }
                if ($scope.model && !picker.endDate.isSame($scope.model.endDate)) {
                  _setEndDate($scope.model.endDate);
                }
              }
              picker.updateView();
            });
          });
          el.on('hide.daterangepicker', function(ev, picker) {
            return el.removeClass('picker-open');
          });
          el.on('apply.daterangepicker', function(ev, picker) {
            return $scope.$apply(function() {
              if (opts.singleDatePicker) {
                if (!picker.startDate) {
                  $scope.model = null;
                } else if (!picker.startDate.isSame($scope.model)) {
                  $scope.model = picker.startDate;
                }
              } else if (!picker.startDate.isSame(picker.oldStartDate) || !picker.endDate.isSame(picker.oldEndDate) || !$scope.model || !picker.startDate.isSame($scope.model.startDate) || !picker.endDate.isSame($scope.model.endDate)) {
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
                picker.cancelingClick = true;
                return picker.clickCancel();
              });
            } else {
              return picker.clickApply();
            }
          });
          for (eventType in opts.eventHandlers) {
            el.on(eventType, function(ev, picker) {
              var eventName;
              eventName = ev.type + '.' + ev.namespace;
              return $scope.$evalAsync(opts.eventHandlers[eventName]);
            });
          }
          modelCtrl.$validate();
          if (!$scope.model) {
            return el.trigger('change');
          }
        };
        $scope.$watch((function() {
          return getViewValue($scope.model);
        }), function(viewValue) {
          if (typeof modelCtrl.$processModelValue === "function") {
            modelCtrl.$processModelValue();
            return modelCtrl.$render();
          } else {
            if (typeof modelCtrl.$$updateEmptyClasses === "function") {
              modelCtrl.$$updateEmptyClasses(viewValue);
            }
            modelCtrl.$viewValue = modelCtrl.$$lastCommittedViewValue = viewValue;
            return modelCtrl.$render();
          }
        });
        modelCtrl.$validators['invalid'] = function(value, viewValue) {
          var applicable, check;
          applicable = attrs.required && !modelCtrl.$isEmpty(viewValue);
          if (opts.singleDatePicker) {
            check = value && value.isValid();
          } else {
            check = value && value.startDate && value.startDate.isValid() && value.endDate && value.endDate.isValid();
          }
          return !applicable || !!check;
        };
        _validateRange = function(date, min, max) {
          var ref;
          if (date && (min || max)) {
            ref = [date, min, max].map(function(d) {
              if (d) {
                return moment(d);
              } else {
                return d;
              }
            }), date = ref[0], min = ref[1], max = ref[2];
            return (!min || min.isBefore(date) || min.isSame(date, 'day')) && (!max || max.isSame(date, 'day') || max.isAfter(date));
          } else {
            return true;
          }
        };
        _initBoundaryField = function(field, validator, modelField, optName) {
          modelCtrl.$validators[field] = function(value) {
            if (!opts[optName]) {
              return true;
            }
            if (opts.singleDatePicker) {
              if (field === 'min') {
                return !value || validator(value, opts['minDate'], value);
              } else if (field === 'max') {
                return !value || validator(value, value, opts['maxDate']);
              }
            } else {
              return value && validator(value[modelField], opts['minDate'], opts['maxDate']);
            }
          };
          if (attrs[field]) {
            return $scope.$watch(field, function(date) {
              opts[optName] = date ? moment(date) : false;
              if (_picker) {
                _picker[optName] = opts[optName];
                return $timeout(function() {
                  return modelCtrl.$validate();
                });
              }
            });
          }
        };
        _initBoundaryField('min', _validateRange, 'startDate', 'minDate');
        _initBoundaryField('max', _validateRange, 'endDate', 'maxDate');
        $scope.$watch('opts', function(newOpts) {
          if (newOpts == null) {
            newOpts = {};
          }
          opts = _mergeOpts(opts, newOpts);
          return _init();
        }, true);
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
              return el.on('cancel.daterangepicker', function(ev, picker) {
                if (!picker.cancelingClick) {
                  $scope.model = opts.singleDatePicker ? null : {
                    startDate: null,
                    endDate: null
                  };
                  el.val("");
                }
                picker.cancelingClick = null;
                return $timeout(function() {
                  return $scope.$apply();
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
