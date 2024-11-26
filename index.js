const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');
const AWS = require('aws-sdk');

const secretsManager = new AWS.SecretsManager();

// Configure the client to retrieve public keys from Microsoft
const client = jwksClient({
  jwksUri: 'https://login.microsoftonline.com/fcb2b37b-5da0-466b-9b83-0014b67a7c78/discovery/keys' // Update with your JWKS URL
});

// Helper function to retrieve signing key from kid (key ID)
function getKey(header, callback) {
  client.getSigningKey(header.kid, (err, key) => {
    if (err) {
      return callback(err);
    }
    const signingKey = key.getPublicKey();
    callback(null, signingKey);
  });
}
function parseQueryString(queryString) {
    const params = {};
    if (!queryString) return params;

    // Split the query string into individual key-value pairs
    const pairs = queryString.split('&');
    pairs.forEach(pair => {
        const [key, value] = pair.split('=');
        if (key) {
            params[decodeURIComponent(key)] = decodeURIComponent(value || '');
        }
    });
    return params;
}
// Function to verify token
function verifyToken(token) {
    return new Promise((resolve, reject) => {
      jwt.verify(token, getKey, { algorithms: ['RS256'] }, (err, decoded) => {
        if (err) {
          reject(`Token verification failed: ${err.message}`);
        } else {
            console.log('Token is:', decoded);
          resolve(decoded); // token is valid
        }
      });
    });
  }
exports.handler = async (event, context, callback) => {
    const request = event.Records[0].cf.request;
    const headers = request.headers;
    const queryString = request.querystring;
    const secretName = 'timetracking-web'; // Replace with your secret names

    const secrets = {};
    // Parse the query string into an object
    const queryParams = parseQueryString(queryString);

    
        const data = await secretsManager.getSecretValue({ SecretId: secretName }).promise();
        let secret;

        if ('SecretString' in data) {
            secret = data.SecretString;
        } else {
            let buff = Buffer.from(data.SecretBinary, 'base64');
            secret = buff.toString('ascii');
        }

         // Store the secret in an object
    
    secret = JSON.parse(secret)
    const clientId = secret.clientId;
    const tenantId = secret.tenantId;
    const code_challenge = secret.code_challenge;
    const code_challenge_method = secret.code_challenge_method
    const redirectUri = secret.redirectUri;

    const authUrl = `https://login.microsoftonline.com/${tenantId}/oauth2/v2.0/authorize?` +
    `client_id=${clientId}&` +
    `response_type=code&` +
    `redirect_uri=${redirectUri}&` +
    `code_challenge=${code_challenge}&`+
    `code_challenge_method=${code_challenge_method}&`+
    `scope=6a0de96b-1426-4351-805f-4cab20da188f/.default offline_access openid`;


        const response = {
            status: '302',
            statusDescription: 'Found',
            headers: {
                location: [{
                    key: 'Location',
                    value: authUrl,
                }],
            },
        };

    
    // Function to get a cookie value by name
    const getCookieValue = (cookieName) => {
        const cookies = headers.Cookie ? headers.Cookie[0].value.split('; ') : [];
        for (const cookie of cookies) {
            const [name, value] = cookie.split('=');
            if (name === cookieName) {
                return value;
            }
        }
        return null;
    };

    // Your cookie name for authentication
    const authCookieName = 'access_token'; 
    // Assuming you are looking for a token parameter
    const authCookie = queryParams['access_token'] || null;
    // Check for the authentication cookie
    // const authCookie = getCookieValue(authCookieName);

    if (!authCookie) {
        // Redirect to IDP for authentication
        return {
            status: '302',
            statusDescription: 'Cookie failed',
            headers: {
                location: [{
                    key: 'Location',
                    value: authUrl,
                }],
                test: [{
                    key: 'Test',
                    value: 'cookied 404',
                }]
            },
        };//response;
    }

    try {
        // Verify the JWT
        //const decoded = jwt.verify(authCookie, getKey, { algorithms: ['RS256'] });
        verifyToken(authCookie)
        .then((decoded) => {
            console.log('Token is valid:', decoded);
            return request;
        })
        .catch((error) => {
            return {    
                status: '302',
                statusDescription: 'Verification failed',
                headers: {
                    location: [{
                        key: 'Location',
                        value: authUrl,
                    }],
                    test: [{
                        key: 'Test',
                        value: 'verification failed',
                    }]
                },
            };
        });
        // If verification is successful, allow the request to pass through
        // You can also add any additional claims checks here if needed
    } catch (err) {
        // If JWT is invalid, redirect to IDP for re-authentication
        console.log(err)
        return {    
            status: '302',
            statusDescription: 'Verification failed',
            headers: {
                location: [{
                    key: 'Location',
                    value: authUrl,
                }],
                test: [{
                    key: 'Test',
                    value: 'verification failed',
                }]
            },
        };//response;
    }

    // If everything is fine, strip the Authorization header and return the request
    delete headers.authorization;

    return request;
};
