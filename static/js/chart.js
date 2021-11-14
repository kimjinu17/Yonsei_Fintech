var chart;

function requestData() {
    $.ajax({
        url: '/live_resource',
        success: function(point) {
            console.log(point)
            var series = chart.series[0],
                shift = series.data.length > 60;

            chart.series[0].addPoint(point, true, shift);

            setTimeout(requestData, 10);
        },
        cache: false
    });
}

$(document).ready(function() {
    chart = new Highcharts.chart({
        chart: {
            renderTo: 'container',
            defaultSeriesType: 'spline',
            events: {
                load: requestData
            }
        },
        title: {
            text: 'Ecost_an_refin'
        },
        xAxis: {
        },
        yAxis: {
            minPadding: 0.2,
            maxPadding: 0.2,
            title: {
                text: 'Ecost'
            }
        },
        series: [{
            name: 'percent',
            data: []
        }]
    });
});