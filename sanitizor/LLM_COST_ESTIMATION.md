# 💰 LLM Cost Estimation

## Claude Sonnet 4 Pricing
- **Input**: $3.00 per 1M tokens  
- **Output**: $15.00 per 1M tokens
- **Estimation**: ~4 characters = 1 token

## Cost Per Operation

### Spec Sanitization
- **Schema Renaming**: ~$0.05-0.15 per batch (5-10 schemas)
- **Documentation**: ~$0.08-0.20 per batch (10-20 fields)

### Error Fixing
- **Basic Mode** (single file): ~$0.02-0.10 per fix
- **Enhanced Mode** (full project): ~$0.20-2.50 per fix

## Typical Costs

| Project Size | Complete Workflow | Enhanced Fixes |
|--------------|-------------------|----------------|
| **Small API** | ~$1-3 | ~$0.50-1.00 |
| **Medium API** | ~$3-8 | ~$1.00-3.00 |
| **Large API** | ~$8-20 | ~$3.00-8.00 |
| **Enterprise API** | ~$20-50 | ~$8.00-15.00 |

### Real Example
**Large Enterprise API** (315 schemas, 1183 descriptions):
- Schema Renaming: ~32 batches × $0.15 = **~$4.80**
- Documentation: ~79 batches × $0.20 = **~$15.80** 
- **Total Sanitization: ~$20.60**

## Monthly Budget
- **Individual**: $10-50/month
- **Team**: $50-200/month  
- **Enterprise**: $200-500/month

## Configuration
```toml
[sanitizor.fixer]
useProjectContext = true    # Better accuracy, higher cost
maxIterations = 5          # Limit cost runaway
```

**Enhanced mode costs 5-10x more but provides 90%+ accuracy vs 60% basic mode.**