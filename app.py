#!/usr/bin/env python3
"""
User Microservice REST API
A simple Flask microservice for managing users with CRUD operations
"""

from flask import Flask, jsonify, request
from datetime import datetime
import logging
import os

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)

# In-memory database (for demonstration purposes)
users_db = {
    1: {"id": 1, "name": "Alice Johnson", "email": "alice@example.com", "created_at": "2026-01-01T10:00:00Z"},
    2: {"id": 2, "name": "Bob Smith", "email": "bob@example.com", "created_at": "2026-01-02T11:30:00Z"},
    3: {"id": 3, "name": "Charlie Brown", "email": "charlie@example.com", "created_at": "2026-01-03T09:15:00Z"}
}
next_user_id = 4


@app.route('/', methods=['GET'])
def home():
    """Home endpoint - service information"""
    return jsonify({
        "service": "User Microservice",
        "version": "1.0.0",
        "status": "running",
        "description": "REST API for user management",
        "endpoints": {
            "GET /": "Service information",
            "GET /health": "Health check",
            "GET /api/users": "List all users",
            "GET /api/users/<id>": "Get specific user",
            "POST /api/users": "Create new user",
            "PUT /api/users/<id>": "Update user",
            "DELETE /api/users/<id>": "Delete user"
        }
    }), 200


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "total_users": len(users_db)
    }), 200


@app.route('/api/users', methods=['GET'])
def get_users():
    """Get all users"""
    logger.info("Fetching all users")
    return jsonify({
        "success": True,
        "count": len(users_db),
        "users": list(users_db.values())
    }), 200


@app.route('/api/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    """Get specific user by ID"""
    logger.info(f"Fetching user with ID: {user_id}")
    
    if user_id not in users_db:
        logger.warning(f"User {user_id} not found")
        return jsonify({
            "success": False,
            "error": "User not found"
        }), 404
    
    return jsonify({
        "success": True,
        "user": users_db[user_id]
    }), 200


@app.route('/api/users', methods=['POST'])
def create_user():
    """Create a new user"""
    global next_user_id
    
    if not request.json:
        return jsonify({
            "success": False,
            "error": "Request must be JSON"
        }), 400
    
    # Validate required fields
    if 'name' not in request.json or 'email' not in request.json:
        return jsonify({
            "success": False,
            "error": "Missing required fields: name and email"
        }), 400
    
    # Create new user
    new_user = {
        "id": next_user_id,
        "name": request.json['name'],
        "email": request.json['email'],
        "created_at": datetime.utcnow().isoformat() + "Z"
    }
    
    users_db[next_user_id] = new_user
    logger.info(f"Created new user with ID: {next_user_id}")
    next_user_id += 1
    
    return jsonify({
        "success": True,
        "message": "User created successfully",
        "user": new_user
    }), 201


@app.route('/api/users/<int:user_id>', methods=['PUT'])
def update_user(user_id):
    """Update an existing user"""
    if user_id not in users_db:
        logger.warning(f"User {user_id} not found for update")
        return jsonify({
            "success": False,
            "error": "User not found"
        }), 404
    
    if not request.json:
        return jsonify({
            "success": False,
            "error": "Request must be JSON"
        }), 400
    
    # Update user fields
    user = users_db[user_id]
    if 'name' in request.json:
        user['name'] = request.json['name']
    if 'email' in request.json:
        user['email'] = request.json['email']
    
    logger.info(f"Updated user with ID: {user_id}")
    
    return jsonify({
        "success": True,
        "message": "User updated successfully",
        "user": user
    }), 200


@app.route('/api/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    """Delete a user"""
    if user_id not in users_db:
        logger.warning(f"User {user_id} not found for deletion")
        return jsonify({
            "success": False,
            "error": "User not found"
        }), 404
    
    deleted_user = users_db.pop(user_id)
    logger.info(f"Deleted user with ID: {user_id}")
    
    return jsonify({
        "success": True,
        "message": "User deleted successfully",
        "user": deleted_user
    }), 200


@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({
        "success": False,
        "error": "Endpoint not found"
    }), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    logger.error(f"Internal server error: {error}")
    return jsonify({
        "success": False,
        "error": "Internal server error"
    }), 500


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    logger.info(f"Starting User Microservice on port {port}")
    app.run(host='0.0.0.0', port=port, debug=False)
