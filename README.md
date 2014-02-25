# Date Range Picker for Angular and Bootstrap
Angular.js directive for Dan Grossmans's [Bootstrap Datepicker](https://github.com/dangrossman/bootstrap-daterangepicker).

![Date Range Picker screenshot](http://i.imgur.com/zDjBqiS.png)

## Instalation
This directive depends on [Bootstrap Datepicker](https://github.com/dangrossman/bootstrap-daterangepicker), [Bootstrap](http://getbootstrap.com), [Moment.js](http://momentjs.com/) and [jQuery](http://jquery.com/).

All dependencies can be installed via Bower.

## Basic usage
```
<script type="text/javascript" src="jquery.js"></script>
<script type="text/javascript" src="moment.js"></script>
<script type="text/javascript" src="daterangepicker.js"></script>
<script type="text/javascript" src="angular.js"></script>
<script type="text/javascript" src="angular-daterangepicker.js"></script>


<link rel="stylesheet" type="text/css" href="bootstrap.css" />
<link rel="stylesheet" type="text/css" href="daterangepicker-bs3.css" />
```

Prepare model in your controller. The model **must** have `startDate` and `endDate` attributes: 

```
exampleApp.controller('TestCtrl', function ($scope) {
	$scope.date = {startDate: null, endDate: null};
}
```


Then in your HTML just add attribute `date-range-picker` to any input and bind it to model.

```
<div ng-controller="TestCtrl">
<input date-range-picker class="form-control date-picker" type="text" ng-model="date" />
</div>
```

See `example.html` for working demo.

## Advanced usage
Min and max value can be set via additional attributes:

```
<input date-range-picker class="form-control date-picker" type="text" ng-model="date" min="'2014-02-23'" max="'2015-02-25'"/>
```

The date picker can be later customized by passing `options` attribute.

<input date-range-picker class="form-control date-picker" type="text" ng-model="date" 
min="'2014-02-23'" max="'2015-02-25'" options="{separator: ":"}"/>


## Links
See [original documentation](https://github.com/dangrossman/bootstrap-daterangepicker).

