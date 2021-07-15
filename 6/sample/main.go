package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"strings"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	ginadapter "github.com/awslabs/aws-lambda-go-api-proxy/gin"
	"github.com/gin-gonic/gin"
)

var ginLambda *ginadapter.GinLambda

type Event struct {
	Type string `json:"type"`
	Text string `json:"text"`
	User string `json:"user"`
	Channel string `json:"channel"`
}

type Payload struct {
	Challenge string `json:"challenge"`
	Type      string `json:"type"`
	Event     Event  `json:"event"`
}

type ResponseBody struct {
	Text string `json:"text"`
}

// Handler is the main entry point for Lambda. Receives a proxy request and
// returns a proxy response
func Handler(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	if ginLambda == nil {
		// stdout and stderr are sent to AWS CloudWatch Logs
		log.Printf("Gin cold start")
		r := gin.Default()
		r.POST("/", postChallenge)

		ginLambda = ginadapter.New(r)
	}

	return ginLambda.ProxyWithContext(ctx, req)
}

func main() {
	lambda.Start(Handler)
}

func postChallenge(c *gin.Context) {
	payload := Payload{}
	err := c.ShouldBindJSON(&payload)

	if err != nil {
		return
	}

	fmt.Println(payload.Type)
	if payload.Type == "url_verification" {
		c.JSON(http.StatusOK, gin.H{"challenge": payload.Challenge, "message": "ok"})
	} else {
		fmt.Println(payload.Type)
		c.JSON(http.StatusOK, gin.H{"message": "ok"})
	}

	if payload.Type != "event_callback" {
		return
	}
	if payload.Event.User == "XXX" {
		return
	}

        // Event.Type = 'message'
        // Event.Channel = 'C026RLDKRR8' = test-seminer
	if payload.Event.Type == "message" && payload.Event.Channel == "C026RLDKRR8" && strings.Contains(payload.Event.Text, "仲間さん") {
		fmt.Println(payload.Event.Text)
		fmt.Println(payload.Event.Type)
                webhookURL := "https://hooks.slack.com/services/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"
		p, err := json.Marshal(ResponseBody{Text: "<@" + payload.Event.User + "> 悪魔パパの仲魔さんだよ!!!!!！"})
		if err != nil {
			fmt.Println(err)
		}
		resp, err := http.PostForm(webhookURL, url.Values{"payload": {string(p)}})
		if err != nil {
			fmt.Println(err)
		}
		defer resp.Body.Close()

		c.JSON(http.StatusOK, gin.H{"message": "ok"})
        }
}
