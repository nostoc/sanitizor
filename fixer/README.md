# Ballerina AI Code Fixer

An intelligent AI-powered tool that automatically detects and fixes compilation errors in Ballerina projects using advanced language models.

## 🚀 Overview

The Ballerina AI Code Fixer is a sophisticated tool designed to streamline the development process by automatically identifying and resolving compilation errors in Ballerina codebases. Leveraging the power of Anthropic's Claude AI, it provides intelligent, context-aware fixes that maintain code quality and follow Ballerina best practices.

## ✨ Key Features

- **AI-Powered Error Resolution**: Uses Anthropic's Claude Sonnet 4 for intelligent code analysis and fixing
- **Interactive Workflow**: Step-by-step confirmation for each proposed fix
- **Automatic Backup**: Creates backup files before applying changes
- **Iterative Fixing**: Continues fixing until all compilation errors are resolved
- **Progress Tracking**: Detailed feedback and iteration summaries
- **Error Analysis**: Comprehensive parsing of Ballerina compilation errors
- **Multi-file Support**: Handles complex projects with multiple error sources

## 📋 Prerequisites

- Ballerina 2201.12.7 or later
- Valid Anthropic API key
- Internet connection for AI model access

## ⚙️ Configuration

### Environment Setup

1. **API Key Configuration**: Set up your Anthropic API key in `Config.toml`:
   ```toml
   [fixer.fixer]
   apiKey="your-anthropic-api-key-here"
   maxIterations=10
   ```

2. **Environment Variable** (Alternative):
   ```bash
   export ANTHROPIC_API_KEY="your-anthropic-api-key-here"
   ```

### Configuration Parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| `apiKey` | Required | Your Anthropic API key for Claude access |
| `maxIterations` | 10 | Maximum number of fix iterations before stopping |

## 🚀 Installation & Usage

### Quick Start

1. **Clone and Navigate**:
   ```bash
   cd fixer
   ```

2. **Configure API Key**:
   Update `Config.toml` with your Anthropic API key

3. **Run the Fixer**:
   ```bash
   bal run -- <path-to-your-ballerina-project>
   ```

### Usage Examples

**Basic Usage**:
```bash
bal run -- ./my-ballerina-project
```

**With Relative Path**:
```bash
bal run -- ../another-project
```

**With Absolute Path**:
```bash
bal run -- /home/user/ballerina-projects/my-app
```

## 🔄 How It Works

### Workflow Overview

1. **Error Detection**: Analyzes `bal build` output to identify compilation errors
2. **Error Parsing**: Extracts detailed error information (file, line, column, message)
3. **Context Analysis**: Reads source files and prepares context for AI analysis
4. **AI Processing**: Sends code and errors to Claude for intelligent fixing
5. **User Review**: Presents proposed fixes for user approval
6. **Fix Application**: Applies approved changes with automatic backup
7. **Iteration**: Repeats process until all errors are resolved

### Error Types Handled

- Syntax errors
- Type mismatches
- Import resolution issues
- Function signature problems
- Variable declaration errors
- And many more Ballerina compilation issues

## 📊 Interactive Features

### User Confirmation Process

For each proposed fix, the tool provides:
- Clear error description
- Proposed code changes
- Interactive confirmation prompt
- Option to review before applying

### Example Output

```
=== Iteration 1 - Fix for src/main.bal ===
Errors to fix:
  Line 15: undefined symbol 'http:Client'
  Line 23: incompatible types: expected 'string', found 'int'

Proposed fix:
```ballerina
// Fixed code with proper imports and type corrections
```

Apply this fix? (y/n): 
```

## 📁 Project Structure

```
fixer/
├── main.bal                    # Main entry point and CLI interface
├── Config.toml                 # Configuration file
├── Ballerina.toml             # Package definition
├── Dependencies.toml          # Dependencies configuration
├── README.md                  # This documentation
├── FIXER_COST_ESTIMATION.md   # API cost analysis
└── modules/
    ├── fixer/
    │   ├── fixer.bal          # Core fixing logic
    │   └── types.bal          # Type definitions
    └── command_executor/
        └── command_executor.bal # Build command execution
```

## 📈 Performance & Cost

### Typical Performance

- **Processing Time**: 2-5 seconds per file
- **Success Rate**: High success rate for common compilation errors
- **Iteration Efficiency**: Usually resolves most errors within 2-3 iterations

### Cost Estimation

Based on moderate usage (10 fix requests per developer per day):
- **Daily Cost**: ~$1.38
- **Monthly Cost**: ~$41.40

See `FIXER_COST_ESTIMATION.md` for detailed cost analysis.

## 🔧 Advanced Configuration

### Custom Iteration Limits

Adjust the maximum number of fixing iterations:
```toml
[fixer.fixer]
maxIterations=15  # Increase for complex projects
```

### Timeout Settings

The AI model has built-in timeout protection (300 seconds) to prevent hanging on complex fixes.

## 🛠️ Troubleshooting

### Common Issues

1. **API Key Issues**:
   - Ensure your Anthropic API key is valid
   - Check that the key has sufficient credits
   - Verify the key is properly configured in `Config.toml`

2. **Build Failures**:
   - Ensure the target project is a valid Ballerina project
   - Check that all dependencies are properly configured
   - Verify Ballerina version compatibility

3. **No Progress on Fixes**:
   - Some errors may require manual intervention
   - Complex architectural issues may need human review
   - Check if the same errors persist across iterations

### Debug Tips

- Review the generated backup files (`.backup` extension) if fixes need to be reverted
- Check console output for detailed error parsing information
- Monitor API usage if experiencing rate limiting

## 🎯 Best Practices

1. **Review Before Applying**: Always review proposed fixes before confirmation
2. **Backup Management**: Keep track of backup files for important changes
3. **Incremental Fixing**: Fix errors in small batches for better results
4. **Manual Review**: Review complex fixes manually after AI application
5. **Version Control**: Commit changes after successful fix sessions

## 🤝 Contributing

This project is part of the Ballerina sanitizer toolkit. Contributions are welcome for:
- Enhanced error parsing
- Additional AI model support
- Improved user interface
- Performance optimizations

## 📄 License

This project is part of the Ballerina development tools ecosystem.
sudo bal push
## 🔗 Related Tools

- **Sanitizor**: Spec sanitization tool
- **Doc Generator**: Documentation generation tool
- **Example Generator**: Example code generation tool

---

**Note**: This tool uses AI models for code generation. Always review and test generated fixes in a safe environment before deploying to production.