# Ballerina AI Code Fixer

An intelligent AI-powered tool that automatically detects and fixes compilation errors in Ballerina projects using advanced language models.

## Overview

The Ballerina AI Code Fixer is a sophisticated development tool designed to streamline the software development process by automatically identifying and resolving compilation errors in Ballerina codebases. By leveraging the advanced capabilities of Anthropic's Claude AI, it provides intelligent, context-aware fixes that maintain code quality and adhere to Ballerina best practices.

## Key Features

- **AI-Powered Error Resolution**: Utilizes Anthropic's Claude Sonnet 4 for intelligent code analysis and automated fixing
- **Interactive Workflow**: Provides step-by-step confirmation for each proposed fix
- **Automatic Backup**: Creates backup files before applying changes to ensure code safety
- **Iterative Fixing**: Continues the fixing process until all compilation errors are resolved
- **Progress Tracking**: Offers detailed feedback and comprehensive iteration summaries
- **Error Analysis**: Performs thorough parsing of Ballerina compilation errors
- **Multi-file Support**: Handles complex projects with multiple error sources across different files

## Prerequisites

- Ballerina 2201.12.7 or later
- Valid Anthropic API key
- Internet connection for AI model access

## Configuration

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

## Installation and Usage

### Quick Start

1. **Navigate to the fixer directory**:
   ```bash
   cd fixer
   ```

2. **Configure your API key**:
   Update `Config.toml` with your Anthropic API key

3. **Run the fixer**:
   ```bash
   bal run -- <path-to-your-ballerina-project>
   ```

### Usage Examples

**Basic usage**:
```bash
bal run -- ./my-ballerina-project
```

**With relative path**:
```bash
bal run -- ../another-project
```

**With absolute path**:
```bash
bal run -- /home/user/ballerina-projects/my-app
```

## How It Works

### Workflow Overview

The fixing process follows a systematic approach:

1. **Error Detection**: Analyzes `bal build` output to identify compilation errors
2. **Error Parsing**: Extracts detailed error information including file location, line number, column, and error message
3. **Context Analysis**: Reads source files and prepares comprehensive context for AI analysis
4. **AI Processing**: Sends code and errors to Claude for intelligent analysis and fixing
5. **User Review**: Presents proposed fixes for user approval and confirmation
6. **Fix Application**: Applies approved changes with automatic backup creation
7. **Iteration**: Repeats the process until all errors are resolved or maximum iterations reached

### Error Types Handled

The tool can effectively handle various types of compilation errors including:

- Syntax errors
- Type mismatches
- Import resolution issues
- Function signature problems
- Variable declaration errors
- Many other common Ballerina compilation issues

## Interactive Features

### User Confirmation Process

For each proposed fix, the tool provides comprehensive information including:
- Clear and detailed error descriptions
- Complete proposed code changes
- Interactive confirmation prompts
- Options to review changes before applying

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

## Project Structure

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

## Performance and Cost

### Typical Performance

- **Processing Time**: 2-5 seconds per file
- **Success Rate**: High success rate for common compilation errors
- **Iteration Efficiency**: Usually resolves most errors within 2-3 iterations

### Cost Estimation

Based on moderate usage (10 fix requests per developer per day):
- **Daily Cost**: ~$1.38
- **Monthly Cost**: ~$41.40

See `FIXER_COST_ESTIMATION.md` for detailed cost analysis.

## Advanced Configuration

### Custom Iteration Limits

You can adjust the maximum number of fixing iterations to accommodate more complex projects:
```toml
[fixer.fixer]
maxIterations=15  # Increase for complex projects
```

### Timeout Settings

The AI model includes built-in timeout protection (300 seconds) to prevent the system from hanging on complex fixes.

## Troubleshooting

### Common Issues

1. **API Key Issues**:
   - Ensure your Anthropic API key is valid and active
   - Check that the key has sufficient credits available
   - Verify the key is properly configured in `Config.toml`

2. **Build Failures**:
   - Ensure the target project is a valid Ballerina project with proper structure
   - Check that all dependencies are properly configured and accessible
   - Verify Ballerina version compatibility with your project requirements

3. **No Progress on Fixes**:
   - Some complex errors may require manual intervention
   - Architectural issues may need human review and redesign
   - Check if the same errors persist across multiple iterations

### Debug Tips

- Review the generated backup files (with `.backup` extension) if fixes need to be reverted
- Check console output for detailed error parsing information and debugging data
- Monitor API usage if experiencing rate limiting or connection issues

## Best Practices

1. **Review Before Applying**: Always carefully review proposed fixes before confirming application
2. **Backup Management**: Keep track of backup files for important changes and maintain version history
3. **Incremental Fixing**: Process errors in small batches for better results and easier troubleshooting
4. **Manual Review**: Conduct thorough manual reviews of complex fixes after AI application
5. **Version Control**: Commit changes after successful fix sessions to maintain project history

## Contributing

This project is part of the Ballerina sanitizer toolkit. We welcome contributions in the following areas:
- Enhanced error parsing capabilities
- Additional AI model support and integration
- Improved user interface and experience
- Performance optimizations and efficiency improvements

## License

This project is part of the Ballerina development tools ecosystem.

## Related Tools

- **Sanitizor**: Comprehensive spec sanitization tool for cleaning and standardizing code specifications
- **Doc Generator**: Automated documentation generation tool for creating comprehensive project documentation
- **Example Generator**: Intelligent example code generation tool for creating practical code samples

---

**Important Note**: This tool utilizes AI models for automated code generation and modification. Always thoroughly review and test all generated fixes in a safe development environment before deploying changes to production systems.