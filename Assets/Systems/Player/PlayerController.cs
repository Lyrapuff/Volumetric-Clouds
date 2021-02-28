using System.Collections;
using UnityEngine;

namespace SmallTail.Player
{
    [RequireComponent(typeof(CharacterController))]
    public class PlayerController : MonoBehaviour
    {
        [SerializeField] private float _crouchSpeed;
        [SerializeField] private float _walkSpeed;
        [SerializeField] private float _runSpeedBonus;
        
        private CharacterController _character;
        private bool _crouching;

        private void Awake()
        {
            _character = GetComponent<CharacterController>();
        }

        private void Update()
        {
            Move();
            Crouch();
        }

        private void Move()
        {
            bool running = Input.GetButton("Run");
            float horizontal = Input.GetAxisRaw("Horizontal");
            float vertical = Input.GetAxisRaw("Vertical");
            
            float speed = (_crouching ? _crouchSpeed : _walkSpeed) + (running ? _runSpeedBonus : 0f);
            speed *= Time.deltaTime;

            Vector3 movement = Vector3.zero;
            
            movement += transform.right * horizontal;
            movement += transform.forward * vertical;
            
            movement = movement.normalized * speed;

            _character.Move(movement);
            
            Vector3 gravity = Vector3.zero;
            gravity.y = -9f * Time.deltaTime;

            _character.Move(gravity);
        }

        private void Crouch()
        {
            if (Input.GetButton("Crouch"))
            {
                if (!_crouching)
                {
                    StartCoroutine(StartCrouch());
                }

                _crouching = true;
            }
            else
            {
                if (_crouching)
                {
                    StartCoroutine(EndCrouch());
                }
                
                _crouching = false;
            }
        }

        private IEnumerator StartCrouch()
        {
            float time = 0f;

            while (time <= 1f)
            {
                _character.height = Mathf.Lerp(2f, 1f, time);
                
                time += Time.deltaTime * 4f;
                yield return new WaitForEndOfFrame();
            }

            _character.height = 1f;
        }

        private IEnumerator EndCrouch()
        {
            float time = 0f;

            while (time <= 1f)
            {
                _character.height = Mathf.Lerp(1f, 2f, time);
                
                time += Time.deltaTime * 4f;
                yield return new WaitForEndOfFrame();
            }

            _character.height = 2f;
        }
    }
}