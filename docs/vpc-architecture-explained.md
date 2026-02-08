# VPC Architecture — How It Maps to VibeVault

A breakdown of every VPC resource and its role in the VibeVault e-commerce platform.

---

## The VPC — Your Isolated Network on AWS

Think of it as renting a private floor in a building. Everything VibeVault runs inside this `10.0.0.0/16` network — completely isolated from other AWS customers.

---

## Public Subnets (2) — The Front Door

These face the internet. They will host:

| What Goes Here | Why | PRD Requirement |
|:---|:---|:---|
| **Load Balancer (ELB)** | Distributes incoming user traffic across your EKS pods | All — every user request enters here |
| **Kong API Gateway** (via EKS + LB) | Routes `/api/users` to User Service, `/api/products` to Product Service, handles rate limiting and auth | Authentication (6.1), all API routing |

When a user searches for a product or checks out, their request hits the load balancer in the public subnet first.

---

## Private Subnets (2) — Where the Real Work Happens

These have **no direct internet access**. They will host:

| What Goes Here | Why | PRD Requirement |
|:---|:---|:---|
| **EKS Worker Nodes** | Run all 6 microservices as containers | Everything — User, Product, Cart, Order, Payment, Notification services |
| **RDS (MySQL)** | Stores users, products, orders, payments | User Management (1.x), Product Catalog (2.x), Order Management (4.x), Payment (5.x) |
| **Kafka** (on EKS) | Async messaging between services — cart events, order placement, payment confirmation | Cart (3.x), Order (4.1), Payment (5.x), Notifications |
| **Redis** (on EKS) | Cart caching for fast retrieval | Cart & Checkout (3.x) |
| **Elasticsearch** (on EKS) | Product search with typo correction | Product Catalog (2.3) |

Private means RDS can't be reached from the internet — only your EKS pods can talk to it. This is how you get "secure authentication" (PRD 6.1) and "secure transactions" (PRD 5.2).

---

## Internet Gateway — Lets Public Subnets Talk to the Internet

Without this, the load balancer can't receive user traffic. It's the door between AWS and the outside world, but **only** the public subnets use it.

---

## NAT Gateway — Controlled Outbound Access for Private Subnets

Your EKS nodes in private subnets need to:

- Pull Docker images from ECR
- Download Kafka/Redis/Elasticsearch dependencies
- Talk to AWS APIs (CloudWatch, SES for notifications)

The NAT Gateway lets them reach **out** to the internet without allowing anything from the internet to reach **in**. It's a one-way door.

---

## Route Tables — The Traffic Rules

- **Public route table:** traffic for `0.0.0.0/0` (the internet) goes through the Internet Gateway
- **Private route table:** traffic for `0.0.0.0/0` goes through the NAT Gateway

Without these, subnets wouldn't know how to route packets.

---

## Default Security Group (Locked Down) — Zero-Trust Baseline

We emptied it on purpose. When you add EKS and RDS, you'll create explicit security groups like:

- **RDS SG:** only accept connections on port 3306 *from EKS nodes*
- **EKS Node SG:** only accept traffic *from the load balancer*

This prevents accidentally exposing a database to the internet.

---

## 2 Availability Zones — High Availability

Your subnets span `ap-south-1a` and `ap-south-1b` (two physically separate data centers). If one AZ goes down, your services in the other AZ keep running. This matters for:

- RDS Multi-AZ failover
- EKS scheduling pods across AZs
- Load balancer routing to healthy AZ

---

## Full Request Flow Through the VPC

```
User searches "wireless headphones"
        |
        v
  Internet Gateway
        |
        v
  Public Subnet ----> Load Balancer ----> Kong API Gateway
        |
        v
  Private Subnet ----> Product Service (EKS pod)
        |
        v
  Private Subnet ----> Elasticsearch (full-text search)
        |
        v
  Response flows back the same path
```

---

> **In short:** the VPC is the network foundation that every service in the PRD will run on top of.
