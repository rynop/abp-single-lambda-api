
const processEvent = async (event, context) => {
  var response = {
    statusCode: 200,
    headers: {},
    body: JSON.stringify({ message: 'Hello World!' }),
    isBase64Encoded: false
  };
  console.log(response);
  return response;
}

exports.handler = async (event, context) => {
  return processEvent(event, context);
}
