const AWS = require('aws-sdk');
//Lambda
exports.handler = async (event) => {
    console.log("Solicitud de taxi!!", JSON.stringify(event))
    console.log(process.env)
}