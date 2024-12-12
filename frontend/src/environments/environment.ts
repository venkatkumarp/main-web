/* 
--------------
PRODUCTION
--------------

This file Contains all Environment Level Constants
*/

export const environment = {
    ENV: process?.env["ENV"] ?? 'PROD',
    redirectUri:process?.env["redirectURI"] ?? 'redirect_URL', // Dummy URL Will be replaced later
    refreshTokenApi:process?.env["refreshTokenApi"] ?? 'refresh_Token_Api' //dummy url
}