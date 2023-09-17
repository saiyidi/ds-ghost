const api = new GhostAdminAPI({
    url: 'http://localhost:2368',
    key: 'YOUR_ADMIN_API_KEY',
    version: "v1.0"
  });
  
  const {posts} = await api.posts.browse({limit: 'all'});
  
  for (const post of posts) {
    console.log('Deleting %s - %s', post.id, post.title);
    await api.posts.delete({id: post.id})
  }