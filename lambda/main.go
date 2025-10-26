package main

import (
	"context"
	"encoding/json"
	"log"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

type Item struct {
	ProductID string  `json:"product_id"`
	Quantity  int     `json:"quantity"`
	Price     float64 `json:"price"`
}

type Order struct {
	OrderID    string    `json:"order_id"`
	CustomerID int       `json:"customer_id"`
	Status     string    `json:"status"`
	Items      []Item    `json:"items"`
	CreatedAt  time.Time `json:"created_at"`
}

// Handler processes SNS events containing order data
func Handler(ctx context.Context, snsEvent events.SNSEvent) error {
	log.Printf("Received %d SNS records", len(snsEvent.Records))

	for _, record := range snsEvent.Records {
		snsRecord := record.SNS
		log.Printf("Processing SNS message: %s", snsRecord.MessageID)

		// Parse order from SNS message
		var order Order
		if err := json.Unmarshal([]byte(snsRecord.Message), &order); err != nil {
			log.Printf("ERROR: Failed to unmarshal order: %v; message=%s", err, snsRecord.Message)
			// Return error to trigger SNS retry (up to 2 retries)
			return err
		}

		log.Printf("Processing order %s (customer=%d)", order.OrderID, order.CustomerID)

		// Simulate payment verification (3 seconds)
		time.Sleep(3 * time.Second)

		log.Printf("Completed order %s", order.OrderID)
	}

	return nil
}

func main() {
	lambda.Start(Handler)
}
