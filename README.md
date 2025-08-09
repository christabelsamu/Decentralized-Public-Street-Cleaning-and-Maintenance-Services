# Decentralized Public Street Cleaning and Maintenance Services

A comprehensive blockchain-based system for managing municipal street maintenance operations using Clarity smart contracts on the Stacks blockchain.

## Overview

This system consists of five specialized smart contracts that handle different aspects of street maintenance:

1. **Street Sweeping Coordination** - Schedules regular cleaning of roads and debris removal
2. **Snow Removal Management** - Coordinates snow plowing, salting, and ice removal during winter storms
3. **Pothole Repair Tracking** - Manages reporting and repair of road surface damage
4. **Street Sign Maintenance** - Coordinates replacement and maintenance of traffic signs and street markers
5. **Leaf Collection Scheduling** - Manages seasonal leaf pickup and composting programs

## Features

### Street Sweeping Contract
- Schedule regular sweeping routes
- Track completion status
- Manage contractor assignments
- Monitor cleaning frequency

### Snow Removal Contract
- Emergency snow removal coordination
- Salt and plow truck dispatch
- Weather-based priority routing
- Resource allocation tracking

### Pothole Repair Contract
- Citizen reporting system
- Repair priority assessment
- Contractor assignment
- Completion verification

### Street Sign Maintenance Contract
- Sign condition monitoring
- Replacement scheduling
- Inventory management
- Installation tracking

### Leaf Collection Contract
- Seasonal collection scheduling
- Route optimization
- Composting program management
- Pickup completion tracking

## Contract Architecture

Each contract operates independently with the following common features:
- Role-based access control (admin, contractor, citizen)
- Task scheduling and tracking
- Payment and incentive systems
- Reporting and analytics
- Emergency priority handling

## Data Structures

### Common Types
- \`principal\` - User addresses (admins, contractors, citizens)
- \`uint\` - Numeric values (IDs, timestamps, amounts)
- \`(string-ascii 50)\` - Text descriptions and addresses
- \`bool\` - Status flags and completion markers

### Status Types
- Scheduled, In-Progress, Completed, Cancelled
- Priority levels: Low, Medium, High, Emergency

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm
- Stacks wallet for testing

### Installation

\`\`\`bash
git clone <repository-url>
cd street-maintenance-system
npm install
clarinet check
\`\`\`

### Testing

\`\`\`bash
npm test
\`\`\`

### Deployment

\`\`\`bash
clarinet deploy --testnet
\`\`\`

## Usage Examples

### Schedule Street Sweeping
\`\`\`clarity
(contract-call? .street-sweeping schedule-sweeping
"Main Street"
u1640995200
'SP1CONTRACTOR...)
\`\`\`

### Report Pothole
\`\`\`clarity
(contract-call? .pothole-repair report-pothole
"123 Oak Avenue"
"Large pothole blocking traffic"
u3)
\`\`\`

### Request Snow Removal
\`\`\`clarity
(contract-call? .snow-removal request-snow-removal
"Downtown District"
u4
u1640995200)
\`\`\`

## Contract Functions

### Administrative Functions
- \`set-admin\` - Update contract administrator
- \`add-contractor\` - Register new service contractor
- \`set-emergency-mode\` - Enable emergency operations

### Operational Functions
- \`schedule-service\` - Create new maintenance task
- \`assign-contractor\` - Assign task to contractor
- \`complete-task\` - Mark task as completed
- \`cancel-task\` - Cancel scheduled task

### Query Functions
- \`get-task-details\` - Retrieve task information
- \`get-contractor-tasks\` - List contractor assignments
- \`get-area-status\` - Check area maintenance status

## Error Codes

- \`ERR-NOT-AUTHORIZED\` (u100) - Insufficient permissions
- \`ERR-TASK-NOT-FOUND\` (u101) - Invalid task ID
- \`ERR-INVALID-INPUT\` (u102) - Invalid parameter values
- \`ERR-ALREADY-EXISTS\` (u103) - Duplicate entry
- \`ERR-INVALID-STATUS\` (u104) - Invalid status transition
- \`ERR-EMERGENCY-ONLY\` (u105) - Emergency mode required

## Security Considerations

- All contracts implement role-based access control
- Input validation on all public functions
- Emergency override capabilities for critical situations
- Audit trail for all maintenance activities

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For technical support or questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation wiki
- 
