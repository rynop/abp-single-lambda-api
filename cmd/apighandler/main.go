package main

import (
	"context"
	"encoding/json"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

type apiError struct {
	Message string `json:"message"`
	Code    int    `json:"code"`
}

type echoResponse struct {
	Request events.APIGatewayProxyRequest
	Ctx     context.Context
}

func handleRequest(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	responseHeaders := map[string]string{
		"Cache-Control": "no-cache, no-store, max-age=0",
	}

	if request.Headers["X-From-CDN"] != os.Getenv("X_FROM_CDN") {
		err, _ := json.Marshal(apiError{"X-From-CDN header not present. Request did not go through CDN", 1})
		return events.APIGatewayProxyResponse{Body: string(err), Headers: responseHeaders, StatusCode: 400, IsBase64Encoded: false}, nil
	}

	jsonRes, _ := json.Marshal(echoResponse{request, ctx})

	return events.APIGatewayProxyResponse{Body: string(jsonRes), Headers: responseHeaders, StatusCode: 200, IsBase64Encoded: false}, nil
}

func main() {
	lambda.Start(handleRequest)
}
