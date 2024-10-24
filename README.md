# Markr API

## Overview

Markr is a simple API built with Sinatra for processing student test results and aggregating them. It uses Redis for storage and supports importing XML data and retrieving aggregated results.

## Key Assumptions

- **Input Format**: The API expects incoming data in a specific XML format defined by a schema (`xml-payload-schema.xsd`). This schema validates the structure of the incoming data.
- **Redis Availability**: The application assumes that a Redis server is accessible. The default connection is set to `redis://localhost:6379`, but this can be overridden with an environment variable.
- **Data Integrity**: It is assumed that the `student-number` field is unique for each student within a given test, and that the `obtained_marks` field in the XML is a valid numeric value.

## Approach

The application consists of two main endpoints:

1. **GET /results/:testid/aggregate**: This endpoint retrieves aggregated results for a specified test ID, calculating metrics like mean, percentiles, and counts based on the stored student results in Redis.

2. **POST /import**: This endpoint accepts an XML payload containing test results for multiple students. It validates the incoming data against a defined XML schema and stores the results in Redis. If a student's results already exist, it updates the records with higher scores.

The code utilizes `Nokogiri` for XML parsing and schema validation, and `Redis` for data storage. Error handling is implemented to provide meaningful responses for various edge cases.

## Key Features

- **XML Schema Validation**: Ensures data integrity by validating incoming XML payloads against a predefined schema.
- **Aggregated Results Calculation**: Automatically calculates mean and percentiles, providing valuable insights into student performance.
- **Redis for Performance**: Utilizes Redis for efficient data storage and retrieval, ensuring fast responses even with large datasets.
- **Docker Support**: Easily run the application in any environment using Docker and Docker Compose, simplifying setup and dependency management.
- **Security Best Practices**: The application runs as a non-root user, enhancing security and minimizing risks.
- **Robust Error Handling**: Comprehensive error handling provides meaningful responses for various edge cases, improving usability.

## Installation and Running with Docker

To build and run the application using Docker and Docker Compose, follow these steps:

1. **Clone the Repository**:
   ```bash
   git clone git@github.com:S5041RT41/markr-stile.git
   cd markr
   ```

2. **Build and Start the Services**:
   You can build and run the application with the following command:
   ```bash
   docker-compose up --build
   ```
   To run the application in the background, do the following
   ```bash
   docker-compose build
   ```
   ```bash
   docker-compose up -d
   ```

3. **Access the API**:
   The API will be available at `http://localhost:9292`. You can test the endpoints using tools like `curl` or Postman.

## Running Tests

To ensure everything is working correctly, you can run the RSpec tests included in the project:

```bash
bundle exec rspec
```

## Dockerfile Details

The application uses a Dockerfile to define the environment:

- **Ruby Base Image**: The Dockerfile uses `ruby:3.3.5-alpine` for a smaller image size.
- **Non-Root User**: The application runs as a non-root user for enhanced security.
- **Layer Optimization**: It leverages Docker's caching mechanism by copying only the Gemfile and Gemfile.lock initially.

## Performance Considerations for the Markr Service

As the Markr service is designed to handle data ingestion and processing for student exam results, several performance considerations can help ensure the service remains efficient, scalable, and responsive, especially as the volume of data and number of requests increase. Here are key areas to focus on:

#### 1. **Data Ingestion Throughput**

- **Batch Processing**: Instead of processing each XML document individually, consider implementing batch processing. This can significantly reduce overhead by aggregating multiple documents into a single processing operation, thereby improving throughput.

- **Asynchronous Processing**: Use background jobs for processing large volumes of incoming data. This allows the HTTP response to return quickly while processing continues in the background. Tools like Sidekiq or Resque can be integrated for this purpose.

#### 2. **Caching Mechanisms**

- **Result Caching**: Implement caching for frequently accessed aggregate results. By storing calculated statistics in Redis (or using an in-memory cache), you can avoid recalculating these metrics for repeated requests, leading to faster response times.

- **HTTP Caching**: Utilize HTTP caching headers to cache responses at the client or proxy level. This can reduce the number of requests hitting your service for the same data.

#### 3. **Efficient Data Structures**

- **Optimized Redis Usage**: Use appropriate Redis data structures (e.g., hashes, sets) to efficiently store and retrieve student results. This can improve read and write performance.

- **Indexing**: If using a more complex database solution in the future, ensure proper indexing of fields that are frequently queried (e.g., `test-id`), to speed up lookups.

#### 4. **Load Testing**

- **Stress Testing**: Conduct load tests to simulate high traffic conditions. This will help identify bottlenecks in the application, allowing you to optimize resource usage and ensure the service can handle peak loads.

- **Monitoring Tools**: Implement monitoring and logging tools (e.g., Prometheus, Grafana, ELK stack) to track performance metrics and identify issues in real-time. This helps in proactive performance tuning.

#### 5. **Scalability**

- **Horizontal Scaling**: Design the service to support horizontal scaling, allowing multiple instances of the application to run in parallel. This can be achieved through container orchestration tools like Kubernetes.

- **Stateless Services**: Ensure that the application is stateless where possible. This simplifies scaling and load balancing as any instance can handle any request without dependency on local state.

#### 6. **Optimizing Aggregate Calculations**

- **Pre-computed Metrics**: For metrics like mean and percentiles, consider storing pre-computed values that can be updated incrementally as new results come in. This avoids recalculating these statistics from scratch for every request.

- **Using Approximate Algorithms**: For large datasets, consider using approximate algorithms (e.g., HyperLogLog for counting unique entries) to reduce computation time while still providing reasonably accurate results.

#### 7. **Documentation and Best Practices**

- **Document Performance Expectations**: Clearly document any performance expectations and considerations for future developers. This ensures that performance remains a priority in ongoing development.

- **Code Reviews and Best Practices**: Encourage code reviews that focus on performance implications of new features or changes. Adopting best practices in code can help prevent performance issues from arising.

## License

This project is licensed under the MIT License.
