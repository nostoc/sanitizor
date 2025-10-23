# Claude API Cost Estimation: OpenAPI Sanitizor Application

## 1. Executive Summary

This report provides a cost estimation for running the OpenAPI Sanitizor application using Claude Sonnet 4 API. The estimate covers the two main operations: schema renaming and documentation enhancement.

The primary model used is **Claude Sonnet 4** for all AI-powered operations.

Based on the assumptions outlined below, the estimated costs are:

**Estimated cost for 01 openAPI spec**: ~$1.04535

These figures represent operational costs for token processing during the sanitization workflow.

## 2. Scope and Assumptions

This estimate is based on the following scope and a set of key assumptions about user behavior and application architecture. Actual costs may vary depending on API complexity and project size.

**Application Type**: OpenAPI Specification Sanitization   
**Target Users**: Individual developers and development teams  
**Model**: Claude Sonnet 4  

| Metric | Actual Usage | Rationale |
|--------|--------------|-----------|
| Schemas processed | 105 schemas | Large enterprise API (Smartsheet) |
| Documentation fields | 1,183 fields | Comprehensive field documentation |
| Schema renaming batches | 14 requests | ~8 schemas per batch |
| Documentation batches | 88 requests | ~15 fields per batch |
| Average tokens per schema batch | 6,500 input, 280 output | Real measured usage |
| Average tokens per doc batch | 1,800 input, 650 output | Real measured usage |

## 3. Cost Calculation Breakdown

The total cost comprises two main operations: schema renaming and documentation enhancement.

### 3.1. Schema Renaming Costs

**Purpose**: Rename generic 'InlineResponse' schemas to meaningful names using AI analysis.

**Model Price (Claude Sonnet 4)**: 
- Input: $3.00 per 1M tokens
- Output: $15.00 per 1M tokens

**Real Usage Data** (105 schemas, 14 batches):
- Input tokens: 14 × 6,500 = 91,000 tokens
- Output tokens: 14 × 280 = 3,920 tokens
- **Input cost**: (91,000 ÷ 1,000,000) × $3.00 = **$0.273**
- **Output cost**: (3,920 ÷ 1,000,000) × $15.00 = **$0.0588**
- **Total schema renaming cost**: **$0.3318**

### 3.2. Documentation Enhancement Costs

**Purpose**: Add meaningful descriptions to undocumented fields using contextual AI analysis.

**Real Usage Data** (1,034 fields, 69 batches):
- Input tokens: 69 × 1,800 = 124,200 tokens
- Output tokens: 69 × 650 = 44,850 tokens
- **Input cost**: (124,200 ÷ 1,000,000) × $3.00 = **$0.3726**
- **Output cost**: (44,850 ÷ 1,000,000) × $15.00 = **$0.67275**
- **Total documentation cost**: **$1.04535**

### 3.3. Retry Costs

**Purpose**: Additional costs when operations fail and require retries.

**Estimated retry cost**: **$0.1** per API (covers ~10% retry rate for failed operations)


### 3.4 **Total Cost Breakdown**
- Schema Renaming: $0.3318
- Documentation: $1.04535
- Retry buffer: $0.1
- **Total API Cost**: **$1.377**




