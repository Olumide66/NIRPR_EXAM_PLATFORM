window.nirprLogout = async function (destination) {
  try {
    const token = localStorage.getItem('nirpr_token');
    if (token) {
      const response = await fetch('/api/auth/logout', {
        method: 'POST', headers: {Authorization: `Bearer ${token}`}
      });
      if (!response.ok && response.status !== 401 && response.status !== 403) {
        throw new Error('Sign-out could not reach the server. Please try again.');
      }
    }
    localStorage.clear();
    window.location.href = destination;
  } catch (error) {
    window.alert('Sign-out could not reach the server. Please try again.');
  }
};
