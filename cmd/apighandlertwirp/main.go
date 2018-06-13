package main

import (
	"log"
	"net/http"
	"os"

	"github.com/apex/gateway"
	"github.com/rynop/abp-single-lambda-api/pkg/blogserver"
	"github.com/rynop/abp-single-lambda-api/pkg/imageserver"
	"github.com/rynop/abp-single-lambda-api/pkg/serverhooks"
	"github.com/rynop/abp-single-lambda-api/rpc/publicservices"
)

func setupRoutes() http.Handler {
	mux := http.NewServeMux()

	svrHooks := serverhooks.NewServerHooks()

	blogServerHandler := publicservices.NewBlogServer(&blogserver.Server{}, svrHooks)
	wrappedBlogHandler := serverhooks.AddHeadersToContext(blogServerHandler)
	mux.Handle(publicservices.BlogPathPrefix, wrappedBlogHandler)

	imageHandler := publicservices.NewImageServer(&imageserver.Server{}, svrHooks)
	wrappedImageHandler := serverhooks.AddHeadersToContext(imageHandler)
	mux.Handle(publicservices.ImagePathPrefix, wrappedImageHandler)

	return mux
}

func main() {
	mux := setupRoutes()

	listenPort, exists := os.LookupEnv("LOCAL_LISTEN_PORT")
	if exists {
		log.Print("Listening locally on " + listenPort)
		log.Fatal(http.ListenAndServe(":"+listenPort, mux))
	} else {
		log.Fatal(gateway.ListenAndServe("", mux))
	}

}
