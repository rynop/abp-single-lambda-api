'use strict';

console.log('Loading function');

exports.handler = async (event, context) => {
    // console.log('Received event:', JSON.stringify(event, null, 2));
    // console.log('context', JSON.stringify(context, null, 2));
    if (!event.headers || event.headers['X-From-CDN'] !== process.env['X_FROM_CDN']) {
        return {
            statusCode: 400,
            headers: {
                "Cache-Control": "no-cache, no-store, max-age=0"
            },
            body: JSON.stringify({ message: 'X-From-CDN header not present. Request did not go through CDN' }),
            isBase64Encoded: false
        };
    }

    return {
        statusCode: 200,
        headers: {
            "Cache-Control": "no-cache, no-store, max-age=0"
        },
        body: JSON.stringify({ event: event, env: process.env, context: context }),
        isBase64Encoded: false
    };
};