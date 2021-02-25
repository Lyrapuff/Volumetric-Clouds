using UnityEngine;

namespace SmallTail.Player
{
    public class PlayerSpawner : MonoBehaviour
    {
        [SerializeField] private GameObject _playerPrefab;

        private void Start()
        {
            if (_playerPrefab == null)
            {
                Debug.LogError("No player prefab was specified!", this);
                return;
            }

            Instantiate(_playerPrefab, transform.position, Quaternion.identity);
            Destroy(gameObject);
        }
    }
}