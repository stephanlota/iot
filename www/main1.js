let humArr = [], tempArr = [], upArr = [], cpuArr = [];  windArr = [];
let myChart = Highcharts.chart('container1', {
    
    title: {
        text: 'Line chart'
    },

    subtitle: {
        text: 'subtitle'
    },

    yAxis: {
        title: {
            text: 'Values'
        }
    },

    xAxis: {
        categories: upArr
    },

    legend: {
        layout: 'vertical',
        align: 'right',
        verticalAlign: 'middle'
    },

    plotOptions: {
        series: {
            label: {
                connectorAllowed: false
            }
        }
    },
    series: [{
        name: 'Humdity',
        data: []
    }, {
        name: 'Temperature',
        data: []
    }, {
        name: 'CPU',
        data: []
    }, {
        name: 'Wind',
        data: []
    }],

    responsive: {
        rules: [{
            condition: {
                maxWidth: 500
            },
            chartOptions: {
                legend: {
                    layout: 'horizontal',
                    align: 'center',
                    verticalAlign: 'bottom'
                }
            }
        }]
    }
});

let getWheatherData = function () {
    $.ajax({
        type: "GET",
        url: "https://iot-mqtt-s3.s3.eu-west-1.amazonaws.com/datas", 
        dataType: "json",
        async: false,
        success: function (data) {
            console.log('data', data);
            drawChart(data);
        },
        error: function (xhr, status, error) {
            console.error("JSON error: " + status);
        }
    });
}

let drawChart = function (data) {

    let { humidity, temperature, value, wind, timestamps } = data;

    humArr.push(Number(humidity));
    tempArr.push(Number(temperature));
    cpuArr.push(Number(value));
    upArr.push(Number(timestamps));
    windArr.push(Number(wind));
    
    myChart.series[0].setData(humArr , true)
    myChart.series[1].setData(tempArr , true)
    myChart.series[2].setData(cpuArr , true)
    myChart.series[3].setData(windArr , true)
}

let intervalTime = 3 * 1000; // 3 second interval polling, change as you like
setInterval(() => {
    getWheatherData();
}, intervalTime);
